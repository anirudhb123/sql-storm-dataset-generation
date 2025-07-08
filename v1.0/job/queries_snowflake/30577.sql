
WITH movie_hierarchy AS (
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
    WHERE 
        mh.level < 3  
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.id) AS total_cast,
    AVG(CASE 
            WHEN ci.person_role_id IS NOT NULL THEN 1 
            ELSE 0 
        END) AS avg_role_presence,
    COUNT(DISTINCT mi.info) FILTER (WHERE it.info = 'Awards') AS awards_count
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND it.info = 'Awards'
    AND mh.level <= 2 
GROUP BY 
    ak.name, mt.title, mt.production_year, mh.level
ORDER BY 
    total_cast DESC,
    avg_role_presence DESC,
    mt.production_year ASC
LIMIT 100;
