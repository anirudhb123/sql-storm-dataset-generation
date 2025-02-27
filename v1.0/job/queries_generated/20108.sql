WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(mo.info_length) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS recent_movie_rank,
    STRING_AGG(DISTINCT mt.keyword, ', ') AS keywords
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_info mo ON at.id = mo.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword mt ON mk.keyword_id = mt.id
WHERE 
    mo.info IS NOT NULL 
    AND mo.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Plot%')
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
    AND AVG(mo.info_length) > (SELECT AVG(info_length) FROM (SELECT LENGTH(info) AS info_length FROM movie_info) AS lengths)
ORDER BY 
    ak.name, recent_movie_rank
OFFSET 10 ROWS 
FETCH NEXT 20 ROWS ONLY
This query performs a complex analysis involving multiple joins, a recursive common table expression (CTE) for movie hierarchies, and various aggregates and window functions, showcasing an intricate SQL structure.
