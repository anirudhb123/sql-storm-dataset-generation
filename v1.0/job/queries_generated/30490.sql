WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Consider movies from the year 2000 onward
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title, 
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        at.production_year >= 2000
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
    SUM(mi.info IS NOT NULL) AS info_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS rn
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name != ''
GROUP BY 
    ak.id, at.id, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1  -- Only include movies with multiple companies
ORDER BY 
    at.production_year DESC, rn
LIMIT 10;
