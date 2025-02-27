WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    SUM(CASE 
        WHEN mh.level IS NOT NULL THEN 1 
        ELSE 0 
    END) AS related_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    AVG(CASE 
        WHEN t.production_year IS NOT NULL THEN t.production_year 
        ELSE NULL 
    END) AS average_production_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND c.country_code = 'USA'
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC,
    actor_name ASC;
