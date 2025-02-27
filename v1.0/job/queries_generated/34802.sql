WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title, 
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    AVG(CASE 
            WHEN mt.production_year IS NOT NULL THEN 
                EXTRACT(YEAR FROM NOW()) - mt.production_year
            ELSE 
                NULL 
        END) AS avg_age_of_movies,
    MAX(mh.level) AS max_link_level
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND mc.company_type_id IS NOT NULL
    AND ak.name NOT LIKE '%Unknown%'
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY 
    movie_count DESC;
