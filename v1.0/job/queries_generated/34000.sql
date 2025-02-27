WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id,
        mt.season_nr,
        mt.episode_nr
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level,
        mt.episode_of_id,
        mt.season_nr,
        mt.episode_nr
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_linked,
    MAX(mh.production_year) AS latest_production_year,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    AVG(CASE WHEN mt.production_year IS NULL THEN 0 ELSE mt.production_year END) AS average_production_year
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    ak.name IS NOT NULL
    AND (mt.production_year BETWEEN 1990 AND 2023 OR mh.level = 1)
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movies_linked DESC,
    latest_production_year DESC;

This query accomplishes several tasks:

1. **Recursive CTE**: It defines a recursive common table expression called `MovieHierarchy` to create a hierarchy of movies based on links between them, filtering for movies produced after 2000.
  
2. **Joins and Aggregations**: It performs outer joins to gather additional movie information and actor data while aggregating results to present data for actors who have starred in more than five movies in the specified range.

3. **String Aggregations**: It uses `STRING_AGG` to list movie titles associated with each actor.

4. **Complex Conditions**: The where-clause conditions include a comparison of production years and a null safety check.

5. **Grouping and Ordering**: The results are grouped by actor name, counted, averaged, and ordered to highlight top performers based on linked movies. 

6. **Coalescing Values**: It handles `NULL` values in a way that favors non-null production years for average calculations. 

This comprehensive query can be useful in a performance benchmarking scenario to evaluate the complexity of SQL capabilities, making efficient use of numerous SQL constructs.
