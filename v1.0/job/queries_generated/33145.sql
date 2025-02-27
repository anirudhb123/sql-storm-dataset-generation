WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    COUNT(mh.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    AVG(mh.production_year) AS avg_production_year,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(mh.movie_id) > 5
ORDER BY 
    movie_count DESC;
