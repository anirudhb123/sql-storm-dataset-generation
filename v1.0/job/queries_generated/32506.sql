WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.level,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS synopsis,
    COALESCE(SUM(CASE WHEN cc.kind = 'Director' THEN 1 ELSE 0 END), 0) AS director_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    comp_cast_type cc ON mc.company_type_id = cc.id
WHERE 
    mt.production_year >= 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mh.level
ORDER BY 
    COUNT(DISTINCT kc.keyword) DESC, movie_rank;
