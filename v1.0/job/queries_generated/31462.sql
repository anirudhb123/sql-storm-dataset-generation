WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- base case: movies from 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(CASE WHEN mh.production_year IS NOT NULL THEN mh.production_year END) AS avg_production_year,
    STRING_AGG(DISTINCT at.title, ', ') AS movie_titles,
    SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_entries,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    aka_title at ON mh.movie_id = at.id
WHERE 
    a.name IS NOT NULL
    AND (mh.production_year >= 2000 OR mh.production_year IS NULL)
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    rank, total_movies DESC
LIMIT 10;

This query constructs a recursive Common Table Expression (CTE) called `MovieHierarchy` to gather a hierarchy of linked movies starting from those produced after the year 2000. It combines data from several tables, including actors, cast information, movie information, and titles, applying various SQL constructs like aggregates, window functions, and string expressions. The final output is filtered to display actors who have been in more than three movies, sorted by their rank based on movie counts.
