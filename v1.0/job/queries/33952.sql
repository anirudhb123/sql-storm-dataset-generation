WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)

SELECT 
    a.name AS actor_name,
    STRING_AGG(DISTINCT mt.title, ', ') AS connected_movies,
    COUNT(DISTINCT c.movie_id) AS total_roles,
    AVG(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS zero_notes_percentage
FROM 
    cast_info AS c
JOIN 
    aka_name AS a ON c.person_id = a.person_id
LEFT JOIN 
    movie_hierarchy AS mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title AS mt ON c.movie_id = mt.id
WHERE 
    c.nr_order IS NOT NULL 
    AND mt.production_year IS NOT NULL
    AND (mh.level IS NULL OR mh.level <= 3)
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 3
ORDER BY 
    total_roles DESC;
