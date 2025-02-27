WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        0 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (
            SELECT id FROM aka_title WHERE title LIKE '%Avengers%'
        )
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        actor_hierarchy ah
    JOIN 
        cast_info c ON c.movie_id IN (
            SELECT linked_movie_id FROM movie_link ml 
            WHERE ml.movie_id IN (
                SELECT movie_id FROM cast_info WHERE person_id = ah.person_id
            )
        )
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    ah.actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT at.title, ', ') AS titles,
    RANK() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    actor_hierarchy ah
JOIN 
    cast_info c ON ah.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
WHERE 
    at.production_year >= 2010
GROUP BY 
    ah.actor_name
HAVING 
    COUNT(DISTINCT c.movie_id) > 2
ORDER BY 
    actor_rank, ah.actor_name;
