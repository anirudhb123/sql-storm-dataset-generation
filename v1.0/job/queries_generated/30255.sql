WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON at.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.depth < 5  -- Limit the depth of recursion
)

SELECT 
    m.movie_id,
    m.movie_title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_assigned,
    STRING_AGG(DISTINCT ak.name, ', ') AS known_aliases,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    p.info AS person_info
FROM 
    MovieHierarchy AS m
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    person_info AS p ON p.person_id = ci.person_id AND p.info_type_id = 1  -- Assuming 1 is for general info
WHERE 
    m.depth <= 3
GROUP BY 
    m.movie_id, m.movie_title, p.info
HAVING 
    COUNT(DISTINCT ci.person_id) > 10  -- Filter for movies with more than 10 distinct cast members
ORDER BY 
    total_cast DESC, m.movie_title
LIMIT 50;

-- Additionally, evaluate performance by measuring execution time for this query
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    m.movie_id,
    m.movie_title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles_assigned,
    STRING_AGG(DISTINCT ak.name, ', ') AS known_aliases,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    p.info AS person_info
FROM 
    MovieHierarchy AS m
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    person_info AS p ON p.person_id = ci.person_id AND p.info_type_id = 1  -- Assuming 1 is for general info
WHERE 
    m.depth <= 3
GROUP BY 
    m.movie_id, m.movie_title, p.info
HAVING 
    COUNT(DISTINCT ci.person_id) > 10  -- Filter for movies with more than 10 distinct cast members
ORDER BY 
    total_cast DESC, m.movie_title
LIMIT 50;
