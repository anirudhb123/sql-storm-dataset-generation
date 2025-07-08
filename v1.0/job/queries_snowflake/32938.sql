
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
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    cn.name AS company_name,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    AVG(mi.info_length) AS avg_info_length,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS rank_by_year
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    (SELECT 
        movie_id, 
        LENGTH(info) AS info_length
    FROM 
        movie_info
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info = 'description')) mi ON mt.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mt.production_year >= 2000 
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year, cn.name, ak.person_id
HAVING 
    COUNT(DISTINCT mc.company_id) > 5
ORDER BY 
    rank_by_year, movie_title;
