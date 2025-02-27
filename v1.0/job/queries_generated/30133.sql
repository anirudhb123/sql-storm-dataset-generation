WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 1990  -- Starting year for the hierarchy

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    CASE 
        WHEN ak.gender = 'M' THEN 'Male'
        WHEN ak.gender = 'F' THEN 'Female'
        ELSE 'Unknown'
    END AS gender,
    COUNT(*) OVER (PARTITION BY ak.person_id) AS total_movies,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = at.id) AS keyword_count,
    COALESCE(mh.level, -1) AS hierarchy_level
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.id IS NOT NULL 
    AND ak.name IS NOT NULL 
    AND (at.production_year BETWEEN 2000 AND 2023 OR at.note IS NOT NULL)
    AND EXISTS (SELECT 1 
                FROM movie_info mi 
                WHERE mi.movie_id = at.id 
                  AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice'))
ORDER BY 
    total_movies DESC, 
    actor_name, 
    production_year DESC
LIMIT 100;
