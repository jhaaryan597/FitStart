-- Create user_interactions table for ML tracking
CREATE TABLE IF NOT EXISTS public.user_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    venue_id TEXT NOT NULL,
    venue_type TEXT NOT NULL, -- 'sports_venue' or 'gym'
    interaction_type TEXT NOT NULL CHECK (interaction_type IN ('view', 'favorite', 'unfavorite', 'book')),
    interaction_score INTEGER NOT NULL DEFAULT 1, -- view=1, favorite=3, book=5
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Enable Row Level Security
ALTER TABLE public.user_interactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own interactions" ON public.user_interactions;
DROP POLICY IF EXISTS "Users can insert their own interactions" ON public.user_interactions;

-- Create policies
CREATE POLICY "Users can view their own interactions"
    ON public.user_interactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own interactions"
    ON public.user_interactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Create indexes for ML queries
CREATE INDEX IF NOT EXISTS user_interactions_user_id_idx ON public.user_interactions(user_id);
CREATE INDEX IF NOT EXISTS user_interactions_venue_id_idx ON public.user_interactions(venue_id);
CREATE INDEX IF NOT EXISTS user_interactions_type_idx ON public.user_interactions(interaction_type);
CREATE INDEX IF NOT EXISTS user_interactions_created_at_idx ON public.user_interactions(created_at DESC);

-- Create composite index for ML similarity queries
CREATE INDEX IF NOT EXISTS user_interactions_user_venue_idx ON public.user_interactions(user_id, venue_id);

-- View for ML feature engineering
CREATE OR REPLACE VIEW public.user_venue_features AS
SELECT 
    user_id,
    venue_id,
    venue_type,
    COUNT(*) as interaction_count,
    SUM(interaction_score) as total_score,
    MAX(CASE WHEN interaction_type = 'book' THEN 1 ELSE 0 END) as has_booked,
    MAX(CASE WHEN interaction_type = 'favorite' THEN 1 ELSE 0 END) as has_favorited,
    MAX(created_at) as last_interaction
FROM public.user_interactions
GROUP BY user_id, venue_id, venue_type;

-- Grant access to the view
GRANT SELECT ON public.user_venue_features TO authenticated;

-- Function to get similar users based on venue interactions (Collaborative Filtering)
CREATE OR REPLACE FUNCTION public.get_similar_users(
    target_user_id UUID,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
    similar_user_id UUID,
    common_venues INTEGER,
    similarity_score NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    WITH target_user_venues AS (
        SELECT DISTINCT venue_id
        FROM public.user_interactions
        WHERE user_id = target_user_id
    ),
    other_users_similarity AS (
        SELECT 
            ui.user_id,
            COUNT(DISTINCT ui.venue_id) as common_venues,
            (COUNT(DISTINCT ui.venue_id)::NUMERIC / 
             (SELECT COUNT(DISTINCT venue_id) FROM public.user_interactions WHERE user_id = ui.user_id)::NUMERIC) 
             as similarity
        FROM public.user_interactions ui
        INNER JOIN target_user_venues tuv ON ui.venue_id = tuv.venue_id
        WHERE ui.user_id != target_user_id
        GROUP BY ui.user_id
        HAVING COUNT(DISTINCT ui.venue_id) >= 2  -- At least 2 venues in common
    )
    SELECT 
        user_id,
        common_venues::INTEGER,
        similarity::NUMERIC
    FROM other_users_similarity
    ORDER BY similarity DESC, common_venues DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get venue recommendations based on similar users
CREATE OR REPLACE FUNCTION public.get_collaborative_recommendations(
    target_user_id UUID,
    venue_type_filter TEXT DEFAULT NULL,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
    venue_id TEXT,
    venue_type TEXT,
    recommendation_score NUMERIC,
    interacted_by_similar_users INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH similar_users AS (
        SELECT similar_user_id, similarity_score
        FROM public.get_similar_users(target_user_id, 10)
    ),
    target_user_venues AS (
        SELECT DISTINCT venue_id
        FROM public.user_interactions
        WHERE user_id = target_user_id
    ),
    recommended_venues AS (
        SELECT 
            ui.venue_id,
            ui.venue_type,
            SUM(su.similarity_score * ui.interaction_score) as score,
            COUNT(DISTINCT ui.user_id) as user_count
        FROM public.user_interactions ui
        INNER JOIN similar_users su ON ui.user_id = su.similar_user_id
        LEFT JOIN target_user_venues tuv ON ui.venue_id = tuv.venue_id
        WHERE tuv.venue_id IS NULL  -- Exclude venues the user has already interacted with
            AND (get_collaborative_recommendations.venue_type_filter IS NULL OR ui.venue_type = get_collaborative_recommendations.venue_type_filter)
        GROUP BY ui.venue_id, ui.venue_type
    )
    SELECT 
        rv.venue_id,
        rv.venue_type,
        rv.score::NUMERIC,
        rv.user_count::INTEGER
    FROM recommended_venues rv
    ORDER BY rv.score DESC, rv.user_count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_similar_users TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_collaborative_recommendations TO authenticated;
