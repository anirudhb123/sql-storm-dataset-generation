WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id,
           m.title,
           m.production_year,
           0 AS depth
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
      AND m.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT m.id,
           m.title,
           m.production_year,
           mh.depth + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movie_count,
    MAX(mh.depth) AS max_depth,
    COALESCE(GROUP_CONCAT(DISTINCT CONCAT(mk.keyword, ': ', mk.id) ORDER BY mk.keyword), 'No keywords') AS keywords,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_count,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE NULL END) AS avg_production_year
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN movie_companies mc ON ci.movie_id = mc.movie_id
JOIN aka_title mt ON ci.movie_id = mt.id
LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN title t ON mt.id = t.id
LEFT JOIN person_info p ON ak.person_id = p.person_id
LEFT JOIN movie_hierarchy mh ON mt.id = mh.movie_id
WHERE ak.name IS NOT NULL
  AND mt.production_year IS NOT NULL
GROUP BY ak.name, mt.title
HAVING COUNT(DISTINCT ml.linked_movie_id) > 0
ORDER BY avg_production_year DESC, actor_name ASC;

Explanation:
1. A recursive CTE (`movie_hierarchy`) builds a hierarchy of movies linked to each other, starting from movies produced between 2000 and 2023.
2. The main query joins multiple tables, including `aka_name`, `cast_info`, `movie_companies`, and `aka_title`, to gather data about actors and movies.
3. It uses `LEFT JOIN` to include optional keyword data related to the movies.
4. It employs conditional aggregations to count female cast members and compute averages for production years.
5. The grouping is done by actor name and movie title, with filtering applied in the `HAVING` clause to ensure linked movies exist.
6. Finally, the results are ordered by average production year in descending order and actor name in ascending order.
