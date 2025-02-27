WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS depth,
        NULL AS parent_movie_id
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL

    SELECT
        lm.id AS movie_id,
        lm.title AS movie_title,
        mh.depth + 1 AS depth,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title lm
    JOIN 
        movie_link ml ON lm.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.depth,
    COALESCE(p.name, 'Unknown') AS director_name,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'director') 
LEFT JOIN 
    aka_name p ON p.id = (SELECT person_id FROM person_info pi WHERE pi.id = mi.id LIMIT 1)
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.depth, p.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    mh.depth, COALESCE(p.name, 'Unknown');
