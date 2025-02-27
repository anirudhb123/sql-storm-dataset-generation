WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL
       
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
    an.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS number_of_companies,
    ROW_NUMBER() OVER (PARTITION BY an.id ORDER BY mh.level DESC) AS movie_rank,
    STRING_AGG(DISTINCT it.info, ', ') AS additional_info
FROM 
    aka_name an
JOIN 
    cast_info ci ON an.person_id = ci.person_id 
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info it ON mh.movie_id = it.movie_id 
WHERE 
    mh.production_year > 2000 
    AND an.name IS NOT NULL 
GROUP BY 
    an.id, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    number_of_companies DESC, movie_rank;
