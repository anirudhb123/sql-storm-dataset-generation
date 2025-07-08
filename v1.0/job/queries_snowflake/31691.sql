
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
    WHERE 
        m.episode_of_id IS NOT NULL
)

SELECT 
    ak.name AS actor_name,
    COUNT(ci.movie_id) AS total_movies,
    AVG(CASE 
            WHEN m.production_year IS NOT NULL THEN m.production_year 
            ELSE NULL 
        END) AS avg_movie_year,
    LISTAGG(DISTINCT mt.title, ', ') AS movie_titles,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_title mt ON m.movie_id = mt.id AND mt.production_year BETWEEN 2000 AND 2020
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(ci.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name;
