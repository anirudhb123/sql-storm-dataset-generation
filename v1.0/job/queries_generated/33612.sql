WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        a.title,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.keyword,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE NULL END) AS avg_roles_assigned,
    MIN(m.production_year) AS first_year,
    MAX(m.production_year) AS last_year
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_title AS m ON mh.movie_id = m.id
LEFT JOIN 
    aka_name AS c ON c.person_id = ci.person_id
WHERE 
    mh.level < 3
GROUP BY 
    mh.movie_id, mh.title, mh.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    avg_roles_assigned DESC, first_year DESC
LIMIT 100;
