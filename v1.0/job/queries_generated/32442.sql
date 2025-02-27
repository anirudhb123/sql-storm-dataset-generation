WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2020  -- Filter for a specific year
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        mt.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.name AS actor_name,
    at.title AS movie_title,
    ah.id AS actor_id,
    COUNT(DISTINCT m.movie_id) AS number_of_movies,
    SUM(COALESCE(l.length, 0)) AS total_linked_movies_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN ai.info_type_id IS NOT NULL THEN LENGTH(ai.info) ELSE NULL END) AS avg_info_length
FROM 
    aka_name ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_link ml ON at.id = ml.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info ai ON at.id = ai.movie_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(linked_movie_id) AS length 
     FROM 
        movie_link 
     GROUP BY 
        movie_id) l ON l.movie_id = at.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
WHERE 
    ah.name IS NOT NULL
    AND at.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    AND at.production_year IS NOT NULL
GROUP BY 
    ah.name, at.title, ah.id
HAVING 
    COUNT(DISTINCT m.movie_id) > 5  -- Example filter on number of movies an actor has
ORDER BY 
    total_linked_movies_length DESC, 
    number_of_movies DESC;
