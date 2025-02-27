WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        CAST(mt.title AS VARCHAR(255)) AS full_name
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.hierarchy_level + 1,
        CAST(mh.full_name || ' > ' || lt.title AS VARCHAR(255))
    FROM
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    COALESCE(cc.name, 'Unknown') AS company_name,
    COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.title) AS row_num,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    AVG(ti.rating) AS average_rating
FROM 
    movie_info mi
LEFT JOIN 
    aka_title mv ON mi.movie_id = mv.id
LEFT JOIN 
    movie_companies mc ON mv.id = mc.movie_id
LEFT JOIN 
    company_name cc ON mc.company_id = cc.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(CAST(info AS FLOAT)) AS rating 
     FROM 
         movie_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
     GROUP BY 
         movie_id
    ) ti ON mv.id = ti.movie_id
LEFT JOIN 
    complete_cast cc2 ON mv.id = cc2.movie_id
LEFT JOIN 
    cast_info ci ON cc2.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
WHERE 
    mv.production_year >= 2000
    AND mv.title NOT LIKE '%unreleased%'
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, cc.name
HAVING 
    COUNT(ci.id) > 0
ORDER BY 
    mv.production_year DESC, mv.title ASC;
