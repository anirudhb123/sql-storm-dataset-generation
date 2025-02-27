
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
top_actors AS (
    SELECT 
        a.person_id,
        ak.name
    FROM 
        actor_movie_counts a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
    WHERE 
        a.movie_count = (SELECT MAX(movie_count) FROM actor_movie_counts)
)
SELECT 
    rt.title,
    rt.production_year,
    ta.name AS top_actor,
    COUNT(DISTINCT c.movie_id) AS total_movies_with_actor
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_info c ON rt.title_id = c.movie_id
LEFT JOIN 
    top_actors ta ON c.person_id = ta.person_id
GROUP BY 
    rt.title, rt.production_year, ta.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 0
ORDER BY 
    rt.production_year DESC,
    rt.title ASC;
