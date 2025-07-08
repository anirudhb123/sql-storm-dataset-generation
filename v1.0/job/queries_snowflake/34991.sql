
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
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    co.name AS company_name,
    COUNT(DISTINCT mc.id) AS total_companies,
    SUM(CASE WHEN mp.info IS NOT NULL THEN 1 ELSE 0 END) AS has_info_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS actor_movie_rank,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS movie_keywords
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mp ON mt.id = mp.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'IMDb Rating')
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year >= 2000
    AND (co.name IS NULL OR co.country_code = 'USA')
GROUP BY 
    ak.name, mt.title, mt.production_year, co.name, ak.person_id
HAVING 
    COUNT(DISTINCT mc.id) > 2
ORDER BY 
    actor_movie_rank, ak.name;
