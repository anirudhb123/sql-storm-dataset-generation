WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS title_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
) 

SELECT 
    rt.production_year,
    COUNT(DISTINCT rt.movie_title) AS total_movies,
    STRING_AGG(rt.movie_title, ', ') AS movie_titles,
    COUNT(DISTINCT rt.actor_name) AS total_actors,
    STRING_AGG(DISTINCT rt.actor_name, ', ') AS actor_names
FROM 
    RankedTitles rt
WHERE 
    rt.title_rank <= 5
GROUP BY 
    rt.production_year
ORDER BY 
    rt.production_year DESC;
