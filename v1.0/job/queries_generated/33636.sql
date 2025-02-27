WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year = 2023
    
    UNION ALL
    
    SELECT 
        m.id, 
        m.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)

SELECT 
    a.name AS actor_name,
    count(DISTINCT mc.movie_id) AS total_movies,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    SUM(CASE WHEN ai.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS awards_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    person_info ai ON a.person_id = ai.person_id AND ai.info_type_id IN (SELECT id FROM info_type WHERE info = 'Award')
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    SUM(CASE WHEN mh.level > 0 THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_movies DESC, 
    awards_count DESC
LIMIT 10;

