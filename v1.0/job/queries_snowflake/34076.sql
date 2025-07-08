WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    a.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT kc.keyword) AS total_keywords,
    AVG(mi.info_length) AS avg_info_length
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    (SELECT 
        movie_id,
        LENGTH(info) AS info_length
     FROM 
        movie_info
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'summary')) mi ON mh.movie_id = mi.movie_id
GROUP BY 
    a.name, a.id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 0
ORDER BY 
    avg_info_length DESC,
    total_keywords DESC;