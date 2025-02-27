WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT cc.id) AS num_characters,
    SUM(mk.keyword) AS num_keywords,
    AVG(pi.info_type_id) AS avg_info_type 
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id 
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%Unknown%'
    AND mh.level <= 3
GROUP BY 
    ak.name, at.title, mh.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 0
ORDER BY 
    mh.production_year DESC, 
    num_characters DESC;
