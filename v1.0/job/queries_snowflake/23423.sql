
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
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind ILIKE '%Movie%')
    
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
    LISTAGG(DISTINCT mh.title, ', ') WITHIN GROUP (ORDER BY mh.title) AS linked_movies,
    COUNT(DISTINCT cn.id) AS production_company_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND (mh.production_year > 2000 OR mh.production_year IS NULL)
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    rank ASC, actor_name ASC
LIMIT 100
OFFSET 0;
