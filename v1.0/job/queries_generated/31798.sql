WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        1 AS level,
        title.title AS movie_title,
        title.production_year,
        NULL::text AS parent_title
    FROM 
        aka_title title
    JOIN 
        movie_companies mc ON title.id = mc.movie_id
    WHERE 
        title.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mh.level + 1,
        mt.title,
        mt.production_year,
        mh.movie_title
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT kc.keyword) AS total_keywords,
    COALESCE(SUM(CASE WHEN c.kind IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_companies,
    MIN(mh.level) AS min_level,
    MAX(mh.level) AS max_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    comp_cast_type c ON mc.company_type_id = c.id
GROUP BY 
    mh.movie_title, 
    mh.production_year
ORDER BY 
    production_year DESC, 
    total_cast DESC
LIMIT 100;
