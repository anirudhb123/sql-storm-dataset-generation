WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    COUNT(DISTINCT cc.subject_id) AS cast_count,
    STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY COUNT(DISTINCT cc.subject_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = cc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    a.name IS NOT NULL
    AND (ci.note IS NULL OR ci.note <> 'Cameo')
    AND mh.level < 3
GROUP BY 
    a.name, m.title
HAVING 
    COUNT(DISTINCT cc.subject_id) > 1
ORDER BY 
    rank, actor_name;
