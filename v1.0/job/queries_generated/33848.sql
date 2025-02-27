WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(ROUND(AVG(mi.info::numeric), 2), 0) AS avg_movie_info,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE mc.company_id IS NOT NULL) AS total_companies,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    COUNT(DISTINCT ak.id) OVER (PARTITION BY mh.level) AS actor_count_at_level
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON cc.movie_id = mh.movie_id
JOIN 
    aka_name ak ON ak.person_id = cc.subject_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kt ON kt.id = mk.keyword_id
JOIN 
    aka_title at ON at.id = mh.movie_id
WHERE 
    ak.name ILIKE '%john%' 
    AND ak.surname_pcode IS NOT NULL
GROUP BY 
    ak.name, at.title, mh.level 
ORDER BY 
    mh.level, ak.name DESC
LIMIT 50;
