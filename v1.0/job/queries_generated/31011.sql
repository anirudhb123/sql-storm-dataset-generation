WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.person_id,
    ak.name AS aka_name,
    mh.title AS linked_movie_title,
    mh.production_year AS linked_movie_year,
    COUNT(ci.id) AS total_cast_roles,
    RANK() OVER(PARTITION BY ah.person_id ORDER BY COUNT(ci.id) DESC) AS role_rank,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
LEFT JOIN 
    info_type it ON cc.status_id = it.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mh.level <= 2
GROUP BY 
    ah.person_id, ak.name, mh.title, mh.production_year
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    role_rank, linked_movie_year DESC;
