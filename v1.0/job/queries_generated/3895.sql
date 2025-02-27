WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)

SELECT 
    ak.name AS actor_name,
    STRING_AGG(DISTINCT mt.title, ', ') AS movies,
    COUNT(DISTINCT mt.id) AS movie_count,
    AVG(mh.production_year) AS avg_year,
    MAX(mh.level) AS max_level,
    CASE 
        WHEN COUNT(DISTINCT mt.id) > 5 THEN 'Prolific'
        ELSE 'Novice'
    END AS actor_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mt.id) > 3
ORDER BY 
    actor_count DESC NULLS LAST;
