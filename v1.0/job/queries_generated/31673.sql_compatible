
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1,
        CAST(mh.path || ' -> ' || m.title AS VARCHAR(255)) AS path
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5  
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    ROW_NUMBER() OVER(PARTITION BY ak.id ORDER BY mt.production_year DESC) AS actor_movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ak.name IS NOT NULL 
    AND ci.note IS NULL
    AND mt.production_year BETWEEN 2005 AND 2020
GROUP BY 
    ak.name, mt.title, mt.production_year, ak.id
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    actor_movie_rank,
    movie_title;
