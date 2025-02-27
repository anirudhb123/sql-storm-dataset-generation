WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS number_of_movies,
    AVG(mh.level) AS average_link_level,
    STRING_AGG(DISTINCT ak.name, ', ') AS co_actors,
    MAX(mi.info) AS latest_movie_note
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
WHERE 
    ci.nr_order = 1
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    number_of_movies DESC
LIMIT 10;

This query performs the following tasks:

1. **Recursive CTE (`MovieHierarchy`)**: It builds a recursive structure to establish the relationships between movies based on linked movies.
   
2. **Joining Tables**: It combines data from `cast_info`, `aka_name`, `movie_info`, and the recursive CTE to gather information about actors, movies, and any associated notes.

3. **Aggregation**: It counts the number of distinct movies each actor has been involved in and calculates the average level of linked movies. It also uses `STRING_AGG` to compile co-actor names.

4. **Filtering**: The results are filtered to include only those actors who have been in more than 5 movies.

5. **Sorting and Limiting**: Finally, it sorts the results by the number of movies and limits the output to the top 10 actors. 

This complex query showcases various SQL concepts including CTEs, joins, aggregations, string functions, and filtering based on aggregates, making it suitable for performance benchmarking.
