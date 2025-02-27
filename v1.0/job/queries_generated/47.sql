WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id DESC) AS rn
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
actor_titles AS (
    SELECT 
        ak.person_id,
        ak.name,
        mt.title,
        mt.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        ranked_movies mt ON ci.movie_id = mt.movie_id
    WHERE 
        mt.rn <= 3
),
release_types AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mt.title) AS title_count
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genres')
    GROUP BY 
        mt.movie_id
)
SELECT 
    at.name AS actor_name,
    COUNT(DISTINCT rt.title_count) AS total_titles,
    STRING_AGG(rt.title_count::text, ', ') AS title_counts,
    CASE 
        WHEN COUNT(rt.title_count) > 0 THEN 'Has Movies'
        ELSE 'No Movies'
    END AS movie_status
FROM 
    actor_titles at 
LEFT JOIN 
    release_types rt ON at.movie_id = rt.movie_id
GROUP BY 
    at.name
HAVING 
    COUNT(rt.title_count) > 1
ORDER BY 
    total_titles DESC NULLS LAST;
