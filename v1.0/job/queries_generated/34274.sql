WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        c.id,
        a.name,
        t.title,
        t.production_year,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.cast_id
    WHERE 
        t.production_year < 2000
),
movie_statistics AS (
    SELECT 
        t.title,
        COUNT(DISTINCT c.person_id) AS total_actors,
        AVG(t.production_year) AS average_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 1980 AND 2023
    GROUP BY 
        t.title
)
SELECT 
    ms.title,
    ms.total_actors,
    ms.average_year,
    ah.actor_name,
    ah.level
FROM 
    movie_statistics ms
LEFT JOIN 
    actor_hierarchy ah ON ms.total_actors > 0
WHERE 
    ms.average_year IS NOT NULL
ORDER BY 
    ms.average_year DESC, ms.total_actors DESC
FETCH FIRST 10 ROWS ONLY;

