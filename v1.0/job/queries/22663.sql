WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

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
)
SELECT
    ak.name AS actor_name,
    ak.name_pcode_nf AS actor_pcode_nf,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(mc.company_id) AS num_companies,
    SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS num_companies_with_notes,
    ARRAY_AGG(DISTINCT kc.keyword) AS keywords,
    RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(mc.company_id) DESC) AS production_rank,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 5 THEN 'High Production'
        WHEN COUNT(DISTINCT mc.company_id) > 2 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_category
FROM
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
WHERE 
    mt.production_year IS NOT NULL
    AND ak.name IS NOT NULL
    AND ak.name_pcode_nf IS NOT NULL
GROUP BY 
    ak.name, ak.name_pcode_nf, mt.title, mt.production_year
HAVING 
    COUNT(mc.company_id) > 2
ORDER BY 
    production_rank, mt.production_year DESC
LIMIT 50;

