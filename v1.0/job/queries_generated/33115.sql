WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, 
           a.name AS actor_name, 
           1 AS level
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IN (SELECT mt.movie_id 
                          FROM movie_title mt 
                          WHERE mt.title LIKE 'A%')  -- filtering for movies starting with 'A'

    UNION ALL

    SELECT ci.person_id, 
           a.name AS actor_name, 
           ah.level + 1
    FROM actor_hierarchy ah
    JOIN cast_info ci ON ah.person_id = ci.person_id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.movie_id IN (SELECT ml.linked_movie_id
                          FROM movie_link ml
                          WHERE ml.movie_id IN (SELECT mt.movie_id 
                                                FROM movie_title mt 
                                                WHERE mt.title LIKE 'A%'))
)

SELECT DISTINCT ah.actor_name, 
                COUNT(DISTINCT ci.movie_id) AS movie_count, 
                MAX(t.production_year) AS latest_movie_year,
                ARRAY_AGG(DISTINCT k.keyword) AS keywords
FROM actor_hierarchy ah
JOIN cast_info ci ON ah.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE ah.level <= 3  -- limiting levels in the hierarchy
AND (t.production_year IS NOT NULL OR t.production_year IS NULL)  -- NULL logic check
GROUP BY ah.actor_name
HAVING COUNT(DISTINCT ci.movie_id) > 1
ORDER BY movie_count DESC, latest_movie_year DESC
LIMIT 10;

-- This query builds a recursive CTE to find actors of a specific set of movies and links 
-- their related movies based on criteria. It includes distinct counts, handling of NULLs, 
-- and aggregation of keywords while enforcing various constraints.
