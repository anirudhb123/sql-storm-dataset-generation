WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ka.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    SUM(CASE WHEN mk.keyword = 'Action' THEN 1 ELSE 0 END) AS action_movies,
    COUNT(DISTINCT m.id) OVER (PARTITION BY ka.id) AS total_movies,
    MIN(mt.production_year) OVER (PARTITION BY ka.id) AS earliest_movie,
    MAX(mt.production_year) OVER (PARTITION BY ka.id) AS latest_movie
FROM 
    aka_name ka
JOIN 
    cast_info ci ON ka.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
WHERE 
    ka.name IS NOT NULL
    AND mt.production_year IS NOT NULL
GROUP BY 
    ka.id, mt.movie_title, mt.production_year
ORDER BY 
    total_movies DESC, latest_movie DESC
FETCH FIRST 10 ROWS ONLY;
