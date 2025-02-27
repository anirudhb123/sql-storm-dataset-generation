WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        ak.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword), 'No keywords') AS keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(mo.production_year) OVER (PARTITION BY ak.id) AS avg_movie_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
    AND (mt.production_year BETWEEN 2000 AND 2023)
GROUP BY 
    ak.id, mt.id
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    avg_movie_year DESC, 
    total_cast DESC
LIMIT 100;
