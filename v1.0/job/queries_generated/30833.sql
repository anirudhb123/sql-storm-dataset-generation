WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
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
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT mg.keyword_id) AS keyword_count,
    AVG(mo.rating) AS average_rating,
    RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company_count,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 5 THEN 'Major Production'
        ELSE 'Independent'
    END AS production_type
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mg ON mg.movie_id = at.id
LEFT JOIN 
    (SELECT 
         movie_id,
         AVG(rating) AS rating
     FROM 
         movie_info
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY 
         movie_id) mo ON mo.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND at.production_year >= 2000
GROUP BY 
    ak.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    at.production_year DESC, rank_by_company_count;
