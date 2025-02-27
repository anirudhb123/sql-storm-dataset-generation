WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Base case for movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        lt.title, 
        lt.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    AVG(CASE WHEN mh.level > 1 THEN mh.level ELSE NULL END) AS avg_movie_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT ch.movie_id) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ch ON a.person_id = ch.person_id
LEFT JOIN 
    movie_keyword mk ON ch.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON ch.movie_id = mh.movie_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 0  -- Only include actors who have acted in movies
ORDER BY 
    total_movies DESC
LIMIT 10;  -- Limit results to top 10 actors based on the number of movies
