
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS total_roles,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ranked_movies t ON c.movie_id = t.movie_id
    GROUP BY 
        c.movie_id, a.name
)
SELECT 
    am.actor_name,
    COALESCE(SUM(rm.year_rank), 0) AS total_year_rank,
    COUNT(DISTINCT am.movie_id) AS number_of_movies,
    MAX(am.total_roles) AS max_roles_per_movie,
    LISTAGG(DISTINCT am.movie_titles, '; ') WITHIN GROUP (ORDER BY am.movie_titles) AS all_movies
FROM 
    actor_movies am
LEFT JOIN 
    ranked_movies rm ON am.movie_id = rm.movie_id 
WHERE 
    am.total_roles > 1
GROUP BY 
    am.actor_name, am.movie_titles
HAVING 
    COUNT(DISTINCT am.movie_id) > 2
ORDER BY 
    number_of_movies DESC, actor_name;
