WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id AS actor_id, 
        a.name AS actor_name, 
        t.title AS top_movie_title, 
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year = 2023
    
    UNION ALL
    
    SELECT 
        c.person_id, 
        a.name, 
        t.title, 
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        actor_hierarchy ah ON c.movie_id IN (
            SELECT movie_id 
            FROM cast_info 
            WHERE person_id = ah.actor_id)
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year < 2023 
        AND ah.level < 5  -- Limit to 5 levels for hierarchy
)
SELECT 
    ah.actor_id, 
    ah.actor_name, 
    STRING_AGG(DISTINCT ah.top_movie_title, ', ') AS movies,
    COUNT(DISTINCT ah.title) AS num_movies,
    MAX(CASE WHEN t.production_year < 2000 THEN 'Classic' ELSE 'Modern' END) AS era,
    COALESCE(NULLIF(STRING_AGG(DISTINCT k.keyword, ', '), ''), 'No keywords') AS keywords
FROM 
    actor_hierarchy ah
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ah.top_movie_title
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title t ON t.id = ah.top_movie_title
GROUP BY 
    ah.actor_id, 
    ah.actor_name
ORDER BY 
    num_movies DESC
LIMIT 50;
