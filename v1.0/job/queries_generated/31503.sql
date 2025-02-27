WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Focus on movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
)
SELECT 
    akn.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.level) AS average_hierarchy_level,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS associated_keywords,
    MAX(mv.title) AS latest_movie_title
FROM 
    MovieHierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name akn ON ci.person_id = akn.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT JOIN 
    aka_title mv ON mh.movie_id = mv.id
WHERE 
    akn.name IS NOT NULL
GROUP BY 
    akn.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5  -- Only include actors with more than 5 movies
ORDER BY 
    total_movies DESC
LIMIT 10;  -- Retrieve the top 10 actors

This query constructs a recursive Common Table Expression (CTE) named `MovieHierarchy` to explore linked movies, focusing on those released from the year 2000 onwards. It joins multiple tables to aggregate actor names, the total number of movies they acted in, their average movie hierarchy level, associated keywords, and the title of their latest movie. The output is filtered for actors who have starred in more than five movies and orders the result to display only the top ten actors based on the number of movies.
