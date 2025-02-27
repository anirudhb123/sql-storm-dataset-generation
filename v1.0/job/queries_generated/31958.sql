WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(cc.id) AS total_characters,
    STRING_AGG(DISTINCT cct.kind, ', ') AS company_types,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY at.production_year DESC) AS actor_rank,
    mh.depth AS movie_depth
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2023
    AND ci.nr_order IS NOT NULL
GROUP BY 
    ak.name, at.title, at.production_year, mh.depth
HAVING 
    COUNT(cc.id) >= 1
ORDER BY 
    actor_rank, movie_depth DESC;
