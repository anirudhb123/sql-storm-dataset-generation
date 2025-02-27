WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title AS movie_title, 1 AS level
    FROM aka_title AS m
    WHERE m.producer_year >= 2000

    UNION ALL

    SELECT m.id, m.title, mh.level + 1
    FROM movie_link AS ml
    JOIN MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN aka_title AS m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(DATE_PART('year', now()) - t.production_year) AS avg_age_of_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN AVG(r.role) IS NULL THEN 'No roles' 
        ELSE AVG(r.role)
    END AS average_role
FROM 
    aka_name AS a
LEFT JOIN 
    cast_info AS c ON a.person_id = c.person_id
LEFT JOIN 
    aka_title AS t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT DISTINCT person_id, role_id AS role 
     FROM role_type) AS r ON c.person_id = r.person_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;
