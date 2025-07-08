
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT cc.movie_id) AS total_movies,
    AVG(COALESCE(m.production_year, 0)) AS average_production_year,
    LISTAGG(DISTINCT COALESCE(t.title, 'No Title'), ', ') WITHIN GROUP (ORDER BY t.title) AS movie_titles,
    RANK() OVER (ORDER BY COUNT(DISTINCT cc.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info cc ON a.person_id = cc.person_id
LEFT JOIN 
    movie_hierarchy m ON cc.movie_id = m.movie_id
LEFT JOIN 
    aka_title t ON cc.movie_id = t.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year IS NOT NULL
    AND a.name NOT LIKE '%Deleted%'
GROUP BY 
    a.name,
    m.production_year
HAVING 
    COUNT(DISTINCT cc.movie_id) > 5
ORDER BY 
    total_movies DESC;
