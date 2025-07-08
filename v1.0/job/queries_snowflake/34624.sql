
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        m.title AS movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    co.name AS company_name,
    mh.movie_id,
    mh.movie_title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT kc.keyword) AS total_keywords,
    MAX(ci.nr_order) AS max_cast_order,
    LISTAGG(DISTINCT CONCAT(a.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_details
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    name a ON ci.person_id = a.imdb_id
JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    co.name IS NOT NULL 
    AND mh.level <= 3
GROUP BY 
    co.name, mh.movie_id, mh.movie_title
ORDER BY 
    total_cast DESC,
    mh.movie_title
LIMIT 10;
