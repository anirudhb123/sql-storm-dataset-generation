WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)
SELECT 
    ak.name AS actor_name,
    a.title AS movie_title,
    a.production_year,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = a.id) AS total_cast,
    COUNT(DISTINCT co.company_id) AS total_production_companies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY a.production_year DESC) AS movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title a ON c.movie_id = a.id
LEFT JOIN 
    movie_companies mc ON a.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ak.name IS NOT NULL 
    AND c.note IS NOT NULL
    AND a.production_year IS NOT NULL
GROUP BY 
    ak.id, a.id
HAVING 
    COUNT(DISTINCT co.company_id) > 1
ORDER BY 
    movie_rank;
