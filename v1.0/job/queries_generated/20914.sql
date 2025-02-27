WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year = (
            SELECT MAX(production_year) 
            FROM aka_title 
            WHERE title IS NOT NULL
        )
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ak.person_id,
    ak.name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    MIN(c.nr_order) AS first_role_order,
    MAX(c.nr_order) AS last_role_order,
    STRING_AGG(DISTINCT at.title, ', ') AS titles,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) = 0 THEN 'No Movies'
        ELSE 'Has Movies'
    END AS movie_status,
    COALESCE(NULLIF(SUBSTRING(ak.name FROM '\w+$'), ''), 'Unnamed') AS last_name_from_input
FROM 
    aka_name ak
LEFT JOIN 
    cast_info c ON ak.person_id = c.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title at ON c.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name != ''
    AND (at.production_year IS NULL OR at.production_year > 2000)
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 1
ORDER BY 
    movie_count DESC, ak.name
LIMIT 50;

-- Additional part of the query to benchmark performance using set operators and NULL logic
SELECT 
    'Top Movies' AS category,
    mt.title,
    mt.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count
FROM 
    aka_title mt
LEFT JOIN 
    cast_info c ON mt.id = c.movie_id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0 

UNION ALL 

SELECT 
    'Movies Without Actors' AS category,
    mt.title,
    mt.production_year,
    NULL AS actor_count
FROM 
    aka_title mt
WHERE 
    mt.id NOT IN (SELECT DISTINCT movie_id FROM cast_info)
    AND mt.production_year < 2000
ORDER BY 
    category, actor_count DESC NULLS LAST;
