WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        a.person_id,
        t.title,
        COUNT(c.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.person_id, t.title
)
SELECT 
    a.name,
    ARRAY_AGG(DISTINCT am.title) AS titles,
    AVG(mo.movie_count) AS avg_movies_per_actor,
    (SELECT COUNT(*) FROM ranked_movies rm WHERE rm.title_rank <= 5) AS top_ranked_movies_count
FROM 
    aka_name a
LEFT JOIN 
    actor_movies am ON a.person_id = am.person_id
LEFT JOIN 
    (SELECT 
         person_id, 
         COUNT(DISTINCT movie_id) AS movie_count
     FROM 
         cast_info
     GROUP BY 
         person_id) mo ON a.person_id = mo.person_id
WHERE 
    a.name IS NOT NULL AND 
    a.name <> '' AND 
    a.name LIKE '%Smith%'
GROUP BY 
    a.id
ORDER BY 
    avg_movies_per_actor DESC
LIMIT 10;
