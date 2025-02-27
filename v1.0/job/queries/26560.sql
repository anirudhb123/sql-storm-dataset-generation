WITH movie_actors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.note AS role_note
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name ILIKE '%John%'  
),

movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_tags
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.note IS NOT NULL
    GROUP BY 
        m.id, m.title
),

actor_movie_info AS (
    SELECT 
        ma.actor_name, 
        ma.movie_title, 
        ma.production_year,
        mis.info_tags
    FROM 
        movie_actors ma
    JOIN 
        movie_info_summary mis ON ma.movie_title = mis.title
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(info_tags, 'No info available') AS info_tags
FROM 
    actor_movie_info
ORDER BY 
    production_year DESC, 
    actor_name;