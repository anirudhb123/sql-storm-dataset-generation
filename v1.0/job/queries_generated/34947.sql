WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY[m.id] AS movie_path
    FROM aka_title m
    WHERE m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        mh.movie_path || e.id
    FROM aka_title e
    JOIN movie_hierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(p.production_year) AS average_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mv.movie_id) AS movie_count_related_to_keywords,
    MAX(CASE WHEN mv.production_year IS NOT NULL THEN mv.production_year ELSE 'Unknown' END) AS latest_production_year,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_notes
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    aka_title p ON mh.movie_id = p.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id
ORDER BY 
    total_movies DESC
LIMIT 10;
