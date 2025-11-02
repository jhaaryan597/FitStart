-- Fix collaborative filtering function with fully qualified column names

-- Drop and recreate get_similar_users function with proper column qualification
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
        SELECT DISTINCT ui.venue_id
        FROM public.user_interactions ui
        WHERE ui.user_id = target_user_id
    ),
    other_users_similarity AS (
        SELECT 
            ui.user_id,
            COUNT(DISTINCT ui.venue_id)::INTEGER as common_venue_count,
            (COUNT(DISTINCT ui.venue_id)::NUMERIC / 
             NULLIF((SELECT COUNT(DISTINCT ui2.venue_id) FROM public.user_interactions ui2 WHERE ui2.user_id = ui.user_id), 0)
            ) as similarity
        FROM public.user_interactions ui
        INNER JOIN target_user_venues tuv ON ui.venue_id = tuv.venue_id
        WHERE ui.user_id != target_user_id
        GROUP BY ui.user_id
        HAVING COUNT(DISTINCT ui.venue_id) >= 2
    )
    SELECT 
        ous.user_id::UUID,
        ous.common_venue_count,
        ous.similarity::NUMERIC
    FROM other_users_similarity ous
    ORDER BY ous.similarity DESC, ous.common_venue_count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate get_collaborative_recommendations function
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
        SELECT su.similar_user_id, su.similarity_score
        FROM public.get_similar_users(target_user_id, 10) su
    ),
    target_user_venues AS (
        SELECT DISTINCT ui.venue_id
        FROM public.user_interactions ui
        WHERE ui.user_id = target_user_id
    ),
    recommended_venues AS (
        SELECT 
            ui.venue_id as rec_venue_id,
            ui.venue_type as rec_venue_type,
            SUM(su.similarity_score * ui.interaction_score) as score,
            COUNT(DISTINCT ui.user_id)::INTEGER as user_count
        FROM public.user_interactions ui
        INNER JOIN similar_users su ON ui.user_id = su.similar_user_id
        LEFT JOIN target_user_venues tuv ON ui.venue_id = tuv.venue_id
        WHERE tuv.venue_id IS NULL
            AND (venue_type_filter IS NULL OR ui.venue_type = venue_type_filter)
        GROUP BY ui.venue_id, ui.venue_type
    )
    SELECT 
        rv.rec_venue_id::TEXT,
        rv.rec_venue_type::TEXT,
        rv.score::NUMERIC,
        rv.user_count
    FROM recommended_venues rv
    ORDER BY rv.score DESC, rv.user_count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_similar_users TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_collaborative_recommendations TO authenticated;
