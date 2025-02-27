WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        mt.title AS full_title
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CONCAT(mh.full_title, ' -> ', at.title) AS full_title
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
)
SELECT 
    mh.full_title,
    mh.production_year,
    ci.person_role_id,
    r.role AS role_name,
    COUNT(DISTINCT ci.id) AS cast_count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_available,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY cast_count DESC) AS rn
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mh.movie_id, mh.full_title, mh.production_year, ci.person_role_id, r.role
HAVING 
    COUNT(DISTINCT ci.id) >= 2
ORDER BY 
    mh.production_year DESC, cast_count DESC
LIMIT 10;
