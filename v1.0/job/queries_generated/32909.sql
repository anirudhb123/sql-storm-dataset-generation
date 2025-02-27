WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
)
SELECT 
    k.keyword,
    COUNT(DISTINCT m.id) AS total_movies,
    AVG(mh.depth) AS avg_depth,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names
FROM 
    movie_keyword AS mk
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    aka_title AS m ON mk.movie_id = m.id
LEFT JOIN 
    cast_info AS ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name AS a ON ci.person_id = a.person_id
LEFT JOIN 
    MovieHierarchy AS mh ON m.id = mh.movie_id
WHERE 
    mh.depth IS NOT NULL
    AND m.production_year BETWEEN 2000 AND 2023
    AND (ci.role_id IN (SELECT id FROM role_type WHERE role LIKE '%actor%'))
GROUP BY 
    k.keyword
HAVING 
    COUNT(DISTINCT m.id) > 10
ORDER BY 
    total_movies DESC;
