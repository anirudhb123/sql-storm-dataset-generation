WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    a.name AS actor_name,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    AVG(mh.level) AS avg_link_level,
    COUNT(DISTINCT m.id) AS total_movies,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN title t ON mh.movie_id = t.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id IS NOT NULL
    AND (t.production_year BETWEEN 2000 AND 2023)
    AND (a.name IS NOT NULL OR a.surname_pcode IS NULL)
GROUP BY a.id
HAVING COUNT(DISTINCT t.id) > 5
ORDER BY total_movies DESC
LIMIT 10;
