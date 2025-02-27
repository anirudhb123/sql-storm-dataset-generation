WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 denotes a specific kind of movie (e.g., "movie")

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT at.title, ', ') AS movie_titles,
    DENSE_RANK() OVER (PARTITION BY ak.name ORDER BY AVG(m.production_year) DESC) AS rank_by_avg_year
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    (SELECT 
         movie_id, COUNT(DISTINCT person_id) AS cast_count
     FROM 
         complete_cast
     GROUP BY 
         movie_id) cc ON cc.movie_id = mh.movie_id
WHERE 
    cc.cast_count > 5 -- Only consider movies with more than 5 actors
GROUP BY 
    ak.name
HAVING 
    avg_production_year > 2000 -- Only consider actors whose movies average post-2000
ORDER BY 
    rank_by_avg_year;
