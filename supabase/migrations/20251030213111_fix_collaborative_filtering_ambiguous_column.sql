-- Fix ambiguous column reference in get_collaborative_recommendations function

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
        SELECT DISTINCT ui.venue_id
        FROM public.user_interactions ui
        WHERE ui.user_id = target_user_id
    ),
    recommended_venues AS (
        SELECT 
            ui.venue_id AS rec_venue_id,
            ui.venue_type AS rec_venue_type,
            SUM(su.similarity_score * ui.interaction_score) as score,
            COUNT(DISTINCT ui.user_id) as user_count
        FROM public.user_interactions ui
        INNER JOIN similar_users su ON ui.user_id = su.similar_user_id
        LEFT JOIN target_user_venues tuv ON ui.venue_id = tuv.venue_id
        WHERE tuv.venue_id IS NULL  -- Exclude venues the user has already interacted with
            AND (get_collaborative_recommendations.venue_type_filter IS NULL 
                 OR ui.venue_type = get_collaborative_recommendations.venue_type_filter)
        GROUP BY ui.venue_id, ui.venue_type
    )
    SELECT 
        rv.rec_venue_id,
        rv.rec_venue_type,
        rv.score::NUMERIC,
        rv.user_count::INTEGER
    FROM recommended_venues rv
    ORDER BY rv.score DESC, rv.user_count DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
