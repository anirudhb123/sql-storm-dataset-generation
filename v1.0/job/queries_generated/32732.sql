WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    ak.name AS actor_name, 
    mt.title AS movie_title, 
    COUNT(DISTINCT mc.company_id) AS company_count,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN mi.info END) AS budget,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN mi.info END) AS rating,
    mh.depth,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS recent_movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year >= 2000
    AND (mi.info IS NOT NULL OR (mi.info IS NULL AND mi.note IS NULL))
GROUP BY 
    ak.name, mt.title, mh.depth
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    actor_name, recent_movie_rank;
