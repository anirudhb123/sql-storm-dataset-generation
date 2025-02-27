WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, 
           m.title AS title, 
           m.production_year, 
           0 AS level
    FROM aka_title m
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT m.id, 
           m.title, 
           m.production_year, 
           mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id 
    WHERE m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    a.name, 
    t.title, 
    t.production_year, 
    COALESCE(c.role_id, 0) AS role_id,
    COUNT(DISTINCT c.nr_order) AS total_appearances,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS appearances_count,
    ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(c.id) DESC) AS appearance_rank
FROM aka_name a
LEFT JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.id
LEFT JOIN MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    (t.production_year >= 2000 AND t.production_year <= 2023)
    OR (mh.level = 0 AND t.production_year < 2000)
GROUP BY a.name, t.title, t.production_year, c.role_id
HAVING COUNT(DISTINCT c.nr_order) > 1
ORDER BY appearance_rank, total_appearances DESC;

This query utilizes a Common Table Expression (CTE) for a recursive movie hierarchy, joining the `aka_name`, `cast_info`, and `aka_title` tables while applying predicates and aggregate functions to derive counts and generate a ranking of appearances.
