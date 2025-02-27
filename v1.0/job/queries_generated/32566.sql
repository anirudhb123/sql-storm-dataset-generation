WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
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
    at.production_year,
    mh.title AS linked_movie_title,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS cast_roles,
    DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS company_rank,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, ak.name) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year IS NOT NULL
    AND (ak.name LIKE '%Smith%' OR ak.name LIKE '%Johnson%')
GROUP BY 
    ak.name, at.production_year, mh.title
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    at.production_year DESC, actor_rank, company_rank;
This SQL query utilizes a recursive Common Table Expression (CTE) to build a hierarchy of movies linked through the `movie_link` table, then aggregates various metrics related to actors from the `aka_name`, `cast_info`, `aka_title`, and `movie_companies` tables. It employs window functions to rank actors per production year while using filtering conditions and NULL logic to ensure only relevant records are processed.
