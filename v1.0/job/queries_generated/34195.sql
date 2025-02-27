WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS depth
    FROM aka_title m
    WHERE m.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT m.id AS movie_id, m.title, m.production_year, mh.depth + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS num_movies,
    AVG(COALESCE(mi.rating, 0)) AS average_rating,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_with_note,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN movie_companies mc ON c.movie_id = mc.movie_id
JOIN movie_info mi ON mi.movie_id = c.movie_id
LEFT JOIN movie_keyword k ON k.movie_id = c.movie_id
JOIN movie_hierarchy mh ON mh.movie_id = c.movie_id
WHERE a.name IS NOT NULL
GROUP BY a.id
HAVING COUNT(DISTINCT ch.movie_id) > 5
ORDER BY average_rating DESC
LIMIT 10;
