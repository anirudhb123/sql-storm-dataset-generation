WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ka.person_id,
    ka.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.movie_title, ', ') AS movie_titles,
    MAX(mh.production_year) AS most_recent_movie
FROM 
    aka_name ka
JOIN 
    cast_info ci ON ka.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
WHERE 
    ka.name ILIKE 'John%'
GROUP BY 
    ka.person_id, ka.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;
