WITH movie_role_counts AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
), 
popular_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN r.role = 'actor' THEN role_count ELSE 0 END), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN r.role = 'director' THEN role_count ELSE 0 END), 0) AS director_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_role_counts r ON m.id = r.movie_id
    GROUP BY 
        m.id, m.title
    HAVING 
        COUNT(DISTINCT r.role) > 1
), 
movie_info_aggregates AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    p.title AS movie_title,
    p.actor_count,
    p.director_count,
    COALESCE(mia.info_details, 'No additional info') AS info
FROM 
    popular_movies p
LEFT JOIN 
    movie_info_aggregates mia ON p.movie_id = mia.movie_id
WHERE 
    p.actor_count > 5
ORDER BY 
    p.actor_count DESC, p.director_count DESC
LIMIT 10;
