WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ma.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    COLLECT(DISTINCT mk.keyword) AS keywords,
    COUNT(DISTINCT c.id) OVER (PARTITION BY actor_name) AS total_movies,
    AVG(mpr.role_count) AS average_roles
FROM 
    movie_hierarchy mt
JOIN 
    cast_info c ON c.movie_id = mt.movie_id
JOIN 
    aka_name ma ON ma.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.movie_id
JOIN 
    (SELECT person_id, COUNT(*) AS role_count FROM cast_info GROUP BY person_id) mpr ON mpr.person_id = c.person_id
WHERE 
    mt.production_year IS NOT NULL
    AND ma.name IS NOT NULL
GROUP BY 
    ma.name, mt.movie_title, mt.production_year
ORDER BY 
    total_movies DESC, actor_name
LIMIT 20;

