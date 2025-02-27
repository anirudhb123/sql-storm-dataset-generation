WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        ak.title,
        ak.production_year,
        ak.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS production_company_names,
    CASE 
        WHEN mh.production_year <= 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2001 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_group
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ak.name IS NOT NULL 
    AND mh.title IS NOT NULL
GROUP BY 
    ak.name, ak.id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mh.production_year DESC,
    ak.name;

