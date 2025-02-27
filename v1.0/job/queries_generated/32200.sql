WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_role_id) AS num_roles,
    STRING_AGG(DISTINCT rt.role, ', ') AS roles,
    MAX(CASE 
        WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN pi.info
        ELSE NULL 
    END) AS movie_rating,
    SUM(CASE 
        WHEN ci.note IS NULL THEN 0 
        ELSE 1 
    END) AS has_notes_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS row_num
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_info pi ON mh.movie_id = pi.movie_id
GROUP BY 
    ak.name, mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_role_id) > 1 
    AND MAX(mh.production_year) < 2020
    AND COUNT(DISTINCT pi.info_type_id) > 0
ORDER BY 
    movie_title, num_roles DESC;
