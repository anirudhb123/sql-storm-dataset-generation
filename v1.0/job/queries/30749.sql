
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_title,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(COALESCE(mk.count, 0)) AS average_keywords
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(DISTINCT keyword_id) AS count 
    FROM movie_keyword 
    GROUP BY movie_id
) mk ON mh.movie_id = mk.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 AND 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    average_keywords DESC, movie_title ASC;
