WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    p.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_count,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    AVG(mh.production_year) AS average_production_year,
    SUM(CASE 
            WHEN (mh.production_year IS NULL) THEN 1 
            ELSE 0 
        END) AS null_years_count,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY movies_count DESC) AS movie_rank
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
WHERE 
    p.name IS NOT NULL
    AND p.name NOT LIKE '%Test%'
GROUP BY 
    p.id, p.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movies_count DESC, actor_name
LIMIT 10;

This SQL query uses a Common Table Expression (CTE) with recursion to generate a hierarchy of movies from the year 2000 onward. It then calculates interesting statistics about the actors involved in these movies, such as the total number of unique movies, a concatenated list of movie titles, and an average production year, while also checking for null values. Finally, the results are ranked and filtered based on particular conditions, providing a comprehensive performance benchmark.
