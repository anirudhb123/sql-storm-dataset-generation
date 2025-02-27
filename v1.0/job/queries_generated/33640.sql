WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 
           COALESCE(mk.keyword, 'No Keywords') AS keyword,
           1 AS level
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, 
           COALESCE(mk.keyword, 'No Keywords') AS keyword,
           mh.level + 1
    FROM aka_title m
    JOIN MovieHierarchy mh ON m.id = mh.movie_id
)

SELECT DISTINCT
    a.name AS actor_name,
    c.role_id AS character_id,
    COUNT(DISTINCT mh.movie_id) OVER (PARTITION BY a.id) AS total_movies,
    SUM(m.production_year) FILTER (WHERE m.production_year IS NOT NULL) OVER (PARTITION BY a.id) AS sum_years,
    STRING_AGG(DISTINCT mh.keyword, ', ') AS keywords
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN title t ON mh.movie_id = t.id
WHERE a.name IS NOT NULL
  AND (mi.note IS NULL OR mi.note LIKE '%awarded%')
GROUP BY a.name, c.role_id
HAVING COUNT(DISTINCT mh.movie_id) > 1
ORDER BY total_movies DESC, sum_years DESC
LIMIT 100;
