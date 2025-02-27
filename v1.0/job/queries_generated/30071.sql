WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023  -- Filtering for the current year

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- Limiting levels of recursion to prevent infinite loops
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    SUM(CASE WHEN p.info_type_id = 1 THEN 1 ELSE 0 END) AS num_person_info,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank_by_company_count
FROM 
    aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN person_info p ON ak.person_id = p.person_id AND p.info_type_id = 1
JOIN aka_title at ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, 
    at.title, 
    at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1  -- Only include actors involved in more than one production company
ORDER BY 
    at.production_year DESC, 
    num_companies DESC;
