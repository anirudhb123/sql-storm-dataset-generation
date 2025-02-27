WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3 
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies,
    ROUND(AVG(m.production_year), 2) AS avg_production_year
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mc.movie_id = mh.movie_id
JOIN 
    title m ON mc.movie_id = m.id
WHERE 
    a.name IS NOT NULL
    AND m.production_year IS NOT NULL
    AND m.production_year >= 2000
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name;