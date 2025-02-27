WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.id] AS movie_path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.movie_path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT ca.person_id) AS cast_member_count,
    CASE 
        WHEN MIN(n.gender) IS NULL THEN 'Unknown'
        ELSE MIN(n.gender)
    END AS primary_gender,
    SUM(CASE 
        WHEN c.role_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS roles_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    name n ON ca.person_id = n.id
LEFT JOIN 
    role_type c ON ca.role_id = c.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 0
ORDER BY 
    mh.production_year DESC, mh.title;
