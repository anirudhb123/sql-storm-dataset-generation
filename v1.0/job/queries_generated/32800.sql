WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT mh.title) AS movie_titles,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS latest_movie_year,
    AVG(CASE 
            WHEN m.info IS NOT NULL THEN 
                LENGTH(m.info)
            ELSE 
                NULL 
        END) AS avg_info_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info m ON mh.movie_id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    total_movies DESC;

This SQL query performs the following:

- It utilizes a recursive common table expression (CTE) `MovieHierarchy` to build a hierarchy of movies linked to each other through the `movie_link` table.
- The query then selects distinct actor names from `aka_name`, aggregates the titles of movies they are in, counts the total number of unique movies, finds the year of their latest movie, and calculates the average length of associated movie plots (from `movie_info` for those that contain data).
- It incorporates `LEFT JOIN` to ensure that the plots are included when available and handles NULL logic in the AVG calculation to exclude NULLs from the average.
- The final results are grouped by actor names, filtered so that only actors with more than one movie are included, and ordered by the total number of movies in descending order.
