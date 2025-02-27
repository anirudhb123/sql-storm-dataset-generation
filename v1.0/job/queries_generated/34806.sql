WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- Limit depth of hierarchy
)

SELECT 
    mk.keyword AS keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    MAX(mh.level) AS max_depth
FROM 
    movie_hierarchy mh
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mk.keyword IS NOT NULL AND (mh.production_year > 2000 OR mh.production_year IS NULL)
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    movie_count DESC, avg_production_year ASC;
