
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        0 AS generation,
        NULL AS parent_actor_id
    FROM aka_name a
    WHERE a.id IN (SELECT DISTINCT person_id FROM cast_info c WHERE c.movie_id IN (SELECT movie_id FROM aka_title WHERE production_year = 2020))
    
    UNION ALL
    
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ah.generation + 1 AS generation,
        ah.actor_id AS parent_actor_id
    FROM aka_name a
    JOIN cast_info c ON c.person_id = a.id
    JOIN actor_hierarchy ah ON ah.actor_id = c.movie_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS number_of_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    MAX(a.generation) AS max_generation
FROM actor_hierarchy a
JOIN cast_info c ON a.actor_id = c.person_id
JOIN aka_title t ON c.movie_id = t.id
WHERE a.actor_name IS NOT NULL
GROUP BY a.actor_name
HAVING COUNT(DISTINCT c.movie_id) > 5
ORDER BY number_of_movies DESC
LIMIT 10;
