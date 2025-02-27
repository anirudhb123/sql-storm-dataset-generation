WITH RECURSIVE MovieHierarchy AS (
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
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
)
SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    th.level,
    th.title AS movie_title,
    th.production_year,
    COUNT(DISTINCT mc.id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy th ON ci.movie_id = th.movie_id
LEFT JOIN 
    movie_companies mc ON th.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    th.production_year BETWEEN 2000 AND 2020
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, ak.id, th.level, th.title, th.production_year
HAVING 
    COUNT(DISTINCT mc.id) > 1
ORDER BY 
    th.level, ak.name
LIMIT 100;
