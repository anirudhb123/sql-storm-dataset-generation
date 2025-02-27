WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.id = a.id
    WHERE 
        t.production_year IS NOT NULL
),
most_popular_movies AS (
    SELECT 
        m.id AS movie_id,
        COUNT(ci.id) AS actor_count
    FROM 
        title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id
    HAVING 
        COUNT(ci.id) > 5
),
movie_details AS (
    SELECT 
        mt.movie_id,
        mt.actor_count,
        mt.movie_id AS most_popular_movie,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COALESCE(mi.info, 'No info available') AS info
    FROM 
        most_popular_movies mt
    LEFT JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    GROUP BY 
        mt.movie_id, mt.actor_count
)
SELECT 
    r.title, 
    r.production_year,
    md.actors,
    md.info,
    CASE 
        WHEN r.year_rank = 1 THEN 'Latest in Production Year'
        ELSE 'Earlier Release'
    END AS release_status
FROM 
    ranked_titles r
JOIN 
    movie_details md ON r.id = md.most_popular_movie
WHERE 
    r.production_year > 2000
ORDER BY 
    r.production_year DESC, 
    md.actor_count DESC;
