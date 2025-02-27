WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movies_count,
    MAX(t.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT tt.title, ', ') AS titles,
    AVG(CASE WHEN ct.kind IS NOT NULL THEN 1 ELSE 0 END) AS company_involvement_ratio
FROM
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title tt ON mh.linked_movie_id = tt.id
WHERE 
    a.name IS NOT NULL
    AND a.name NOT LIKE '%anonymous%'
GROUP BY 
    a.name
ORDER BY 
    movies_count DESC, 
    latest_movie_year DESC
LIMIT 10;
