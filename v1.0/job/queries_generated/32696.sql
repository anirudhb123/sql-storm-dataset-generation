WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    concat(aka.name, ' as ', rt.role) AS actor_role,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN 1 ELSE 0 END) AS has_rating,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rn
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name aka ON aka.person_id = ci.person_id
LEFT JOIN 
    role_type rt ON rt.id = ci.role_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.production_year IS NOT NULL
    AND mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    aka.name, rt.role, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    mh.production_year, num_companies DESC;
