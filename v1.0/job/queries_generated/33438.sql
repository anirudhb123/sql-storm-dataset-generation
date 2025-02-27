WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mh.production_year DESC) AS row_num
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    title t ON mh.movie_id = t.id
WHERE 
    mc.company_type_id IS NULL
    AND (mh.level <= 2 OR mh.production_year < 2010)
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, t.title, mh.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    actor_name, mh.production_year DESC;
