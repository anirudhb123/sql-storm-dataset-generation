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
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(CASE WHEN c.note IS NOT NULL THEN 1 END) AS total_cast,
    SUM(CASE WHEN ci.role_id IN (SELECT id FROM role_type WHERE role = 'lead') THEN 1 ELSE 0 END) AS lead_roles,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS rn
FROM 
    aka_name ak
INNER JOIN 
    cast_info ci ON ak.person_id = ci.person_id
INNER JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT DISTINCT movie_id 
     FROM movie_companies 
     WHERE company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributors 
ON 
    at.id = distributors.movie_id
WHERE 
    at.production_year >= 2000
GROUP BY 
    ak.id, at.id
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    total_cast DESC, movie_title ASC;

