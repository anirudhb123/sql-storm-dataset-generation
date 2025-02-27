WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN
        title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ci.person_role_id, 0) AS person_role_id,
    COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS total_roles,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS year_rank,
    ROW_NUMBER() OVER (ORDER BY total_roles DESC) AS role_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ci.person_role_id
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
    AND mh.production_year IS NOT NULL
ORDER BY 
    mh.production_year DESC, total_roles DESC;
