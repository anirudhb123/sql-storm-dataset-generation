WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, 
           m.title,
           1 AS depth,
           CAST(m.title AS VARCHAR(255)) AS path
    FROM aka_title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT m.id AS movie_id,
           m.title,
           mh.depth + 1,
           CAST(mh.path || ' -> ' || m.title AS VARCHAR(255))
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT ak.name AS actor_name,
       COUNT(DISTINCT h.movie_id) AS movies_count,
       MAX(CASE WHEN h.depth > 1 THEN h.title END) AS linked_movie,
       ARRAY_AGG(DISTINCT m.title ORDER BY m.production_year DESC) AS all_movies,
       STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_hierarchy h ON ci.movie_id = h.movie_id
LEFT JOIN aka_title m ON ci.movie_id = m.id
WHERE ak.name IS NOT NULL
AND ci.nr_order IS NOT NULL
AND (ci.note IS NULL OR ci.note <> 'Cameo')
AND m.production_year BETWEEN 1990 AND 2023
GROUP BY ak.name
HAVING COUNT(DISTINCT h.movie_id) > 5
   OR MAX(h.depth) BETWEEN 2 AND 4
ORDER BY movies_count DESC, actor_name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
