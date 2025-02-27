
WITH movie_actors AS (
    SELECT 
        a.person_id,
        a.name,
        c.movie_id,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
actor_counts AS (
    SELECT 
        person_id,
        COUNT(DISTINCT movie_id) AS movie_count
    FROM 
        movie_actors
    GROUP BY 
        person_id
),
latest_movies AS (
    SELECT 
        person_id,
        name,
        movie_id,
        production_year
    FROM 
        movie_actors
    WHERE 
        rn = 1
)
SELECT 
    lm.name AS actor_name,
    kt.title,
    lm.production_year,
    ac.movie_count
FROM 
    latest_movies lm
JOIN 
    actor_counts ac ON lm.person_id = ac.person_id
LEFT JOIN 
    aka_title kt ON lm.movie_id = kt.id
WHERE 
    ac.movie_count > 2
    AND kt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
ORDER BY 
    lm.production_year DESC
LIMIT 10;
