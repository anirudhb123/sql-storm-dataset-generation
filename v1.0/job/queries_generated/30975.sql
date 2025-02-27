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
        mt.production_year BETWEEN 2000 AND 2020

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    array_agg(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(CASE WHEN pi.info_type_id = it.id THEN pi.info::integer ELSE NULL END) AS average_rating,
    MAX(CASE WHEN pi.info_type_id = it.id THEN pi.info END) AS highest_rating
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
WHERE 
    m.level = 1
GROUP BY 
    a.name, m.title
HAVING 
    COUNT(DISTINCT pi.info_type_id) > 1
ORDER BY 
    average_rating DESC NULLS LAST,
    total_cast DESC;
