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
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mm.id,
        mm.title,
        mm.production_year,
        mm.kind_id,
        mh.level + 1
    FROM 
        aka_title mm
    JOIN 
        movie_link ml ON mm.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(ki.keyword) AS keyword_count,
    MAX(ci.nr_order) AS max_role_order,
    AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS null_role_count,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ki.keyword) DESC) AS keyword_rank
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    ak.name IS NOT NULL
    AND (mt.kind_id IS NOT NULL OR mt.production_year > 2015)
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(ki.keyword) > 1
ORDER BY 
    mt.production_year, keyword_rank;
