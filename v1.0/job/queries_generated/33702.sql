WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mt.title AS VARCHAR)
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.linked_movie_id
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_production_year,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
    MAX(anchor_movie.title) AS latest_movie
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    (SELECT * FROM MovieHierarchy WHERE level = 1) anchor_movie ON mt.id = anchor_movie.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mt.production_year >= 2000
    AND mc.company_id IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC;
