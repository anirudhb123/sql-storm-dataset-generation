WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movie_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
)
SELECT 
    am.actor_id,
    am.name,
    am.movie_count,
    am.movies,
    rt.title,
    rt.production_year,
    CASE 
        WHEN am.movie_count > 5 THEN 'Top Actor'
        WHEN am.movie_count IS NULL THEN 'No Movies'
        ELSE 'Regular Actor'
    END AS actor_category
FROM 
    actor_movie_info am
FULL OUTER JOIN 
    ranked_titles rt ON am.movie_count = rt.year_rank
WHERE 
    rt.production_year IS NOT NULL OR am.movie_count IS NOT NULL
ORDER BY 
    COALESCE(rt.production_year, 0) DESC, 
    am.movie_count DESC;
