WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS hierarchy_level,
        CAST(mt.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        mh.hierarchy_level + 1,
        CAST(mh.full_path || ' -> ' || lt.title AS VARCHAR(255))
    FROM 
        movie_link ml
    JOIN 
        title lt ON ml.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ma.name AS actor_name,
    mt.movie_title,
    mh.hierarchy_level,
    mh.full_path,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER(PARTITION BY ma.name ORDER BY mh.hierarchy_level, mt.production_year DESC) AS row_number
FROM 
    aka_name ma
JOIN 
    cast_info ci ON ma.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
WHERE 
    mt.production_year IS NOT NULL
    AND ma.name IS NOT NULL
GROUP BY 
    ma.name, mt.movie_title, mh.hierarchy_level, mh.full_path
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    actor_name, hierarchy_level;
