WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000 

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    rev.title AS movie_title,
    rev.production_year,
    COUNT(DISTINCT co.id) AS company_count,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY rev.production_year DESC) AS movie_rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy rev ON cc.movie_id = rev.movie_id
LEFT JOIN 
    movie_companies mc ON rev.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON rev.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    ak.name IS NOT NULL 
    AND rev.production_year IS NOT NULL 
    AND rev.level <= 2 
GROUP BY 
    ak.name, rev.title, rev.production_year
ORDER BY 
    actor_name ASC, production_year DESC;
