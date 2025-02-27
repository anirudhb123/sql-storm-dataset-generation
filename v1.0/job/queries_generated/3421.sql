WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rn <= 10
),
actor_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        top_movies t ON ci.movie_id = (SELECT movie_id FROM aka_title WHERE title = t.title LIMIT 1)
)
SELECT 
    am.actor_name,
    STRING_AGG(am.title || ' (' || am.production_year || ')', ', ') AS movies
FROM 
    actor_movies am
GROUP BY 
    am.actor_name
ORDER BY 
    COUNT(am.title) DESC
LIMIT 5;
