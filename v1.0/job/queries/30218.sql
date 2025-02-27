WITH RECURSIVE movie_hierarchy AS (
    
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'similar') 

    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'similar')
)

SELECT 
    t.title AS main_title,
    COUNT(DISTINCT mh.linked_movie_id) AS total_similar_movies,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    AVG(m.production_year) AS avg_production_year,
    MAX(m.production_year) AS latest_production_year,
    MIN(m.production_year) AS earliest_production_year
FROM 
    title t
LEFT JOIN 
    movie_link ml ON t.id = ml.movie_id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id 
LEFT JOIN 
    cast_info ci ON mh.linked_movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    aka_title m ON mh.linked_movie_id = m.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'series')) 
    AND (m.production_year IS NULL OR m.production_year >= 2000) 
GROUP BY 
    t.title
ORDER BY 
    total_similar_movies DESC,
    avg_production_year DESC
LIMIT 10;