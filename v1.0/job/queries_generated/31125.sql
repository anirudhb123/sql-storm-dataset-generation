WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
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
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        mh.level < 5
)

SELECT 
    DISTINCT ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    MAX(mh.production_year) AS last_production_year,
    MIN(mh.production_year) AS first_production_year,
    SUM(CASE WHEN ak.name LIKE 'A%' THEN 1 ELSE 0 END) AS counts_starting_with_a,
    AVG(CASE WHEN rt.role LIKE '%lead%' THEN mci.nr_order END) AS average_lead_role_order,
    COUNT(DISTINCT CASE WHEN mi.info IS NOT NULL THEN mi.movie_id END) AS count_with_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'production')
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    ak.name IS NOT NULL
    AND mh.production_year >= 2000
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    movies_count DESC
LIMIT 10;
