WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  -- Start with top-level movies
    UNION ALL
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mh ON mh.id = ml.linked_movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    MIN(mh.production_year) AS first_movie_year,
    MAX(mh.production_year) AS last_movie_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    AVG(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year ELSE 0 END) AS avg_production_year,
    CASE 
        WHEN COUNT(DISTINCT c.movie_id) > 10 THEN 'Prolific Actor' 
        WHEN COUNT(DISTINCT c.movie_id) BETWEEN 5 AND 10 THEN 'Moderate Actor' 
        ELSE 'Occasional Actor' 
    END AS actor_type,
    COALESCE(NULLIF((SELECT AVG(CAST(c2.nr_order AS float))
                     FROM cast_info c2
                     WHERE c2.movie_id = c.movie_id
                     AND c2.role_id IS NOT NULL), 0), 'N/A') AS avg_role_order
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 0 
ORDER BY 
    total_movies DESC;


This query involves the creation of a recursive common table expression (CTE) to generate a hierarchy of movies, selects actors, counts their total movies, calculates the first and last movie years, concats movie titles, finds the average production year, categorizes actor types based on the count of movies, and computes an average role order while taking care of NULL values through coalesce and nullif functions. Moreover, it sorts the results by the total number of movies each actor has participated in.
