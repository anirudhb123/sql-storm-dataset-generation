WITH RECURSIVE ActorHierarchy AS (
    SELECT c.id AS cast_id, c.person_id, 
           a.name AS actor_name, 
           t.title AS movie_title, 
           t.production_year,
           1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE c.nr_order = 1  

    UNION ALL

    SELECT c.id AS cast_id, c.person_id, 
           a.name AS actor_name, 
           t.title AS movie_title, 
           t.production_year,
           ah.level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN movie_link ml ON c.movie_id = ml.movie_id
    JOIN aka_title t ON ml.linked_movie_id = t.movie_id
    JOIN ActorHierarchy ah ON ah.cast_id = ml.movie_id
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT ah.movie_title) AS movies_count,
    STRING_AGG(DISTINCT ah.movie_title, ', ') AS movie_titles,
    MIN(ah.production_year) AS first_movie_year,
    MAX(ah.production_year) AS last_movie_year,
    AVG(ah.production_year) FILTER (WHERE ah.production_year IS NOT NULL) AS avg_year,
    COUNT(DISTINCT CASE WHEN ah.level = 1 THEN ah.movie_title END) AS lead_roles_count,
    COUNT(DISTINCT CASE WHEN ah.level > 1 THEN ah.movie_title END) AS supporting_roles_count
FROM ActorHierarchy ah
GROUP BY ah.actor_name
HAVING COUNT(DISTINCT ah.movie_title) > 0
ORDER BY movies_count DESC
LIMIT 10;