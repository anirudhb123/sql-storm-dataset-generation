WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'tv%')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT cm.movie_id) AS contributed_movies,
    ARRAY_AGG(DISTINCT mh.movie_title) AS linked_movies,
    AVG(mi.production_year) AS avg_production_year,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'production year')
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (mi.info IS NULL OR mi.info NOT LIKE '%unreleased%')
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT cm.movie_id) > 5
ORDER BY 
    contributed_movies DESC;
