WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mm.movie_id,
        mm.title,
        mm.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    INNER JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    INNER JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mk.movie_id) AS movie_count,
    AVG(CASE WHEN t.production_year IS NOT NULL THEN t.production_year ELSE NULL END) AS average_production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    COUNT(DISTINCT c.person_id) FILTER (WHERE c.note IS NOT NULL) AS distinct_actors_count
FROM 
    MovieHierarchy mh
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
JOIN 
    aka_name ak ON ak.person_id IN (
        SELECT DISTINCT ci.person_id
        FROM cast_info ci
        WHERE ci.movie_id = mh.movie_id
    )
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_title t ON t.id = mh.movie_id
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mk.movie_id) > 2
ORDER BY 
    movie_count DESC
LIMIT 10;

This query creates a recursive Common Table Expression (CTE) `MovieHierarchy` to gather a hierarchy of movies produced since 2000, including linked movies. It then selects keywords associated with those movies, counts distinct movies for each keyword, calculates the average production year, aggregates actor names, and counts distinct actors while considering potential NULLs and filters in the results. Finally, it sorts the results and limits the output for performance benchmarking.
