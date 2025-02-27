WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mk.keyword AS keyword,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS latest_year,
    MAX(CASE WHEN c.role_id IS NOT NULL THEN c.nr_order ELSE NULL END) AS max_role_order,
    AVG(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_percentage,
    STRING_AGG(DISTINCT n.name, ', ') AS actor_names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    name n ON c.person_id = n.id
LEFT JOIN 
    person_info p ON n.imdb_id = p.person_id AND p.info_type_id = (
        SELECT id FROM info_type WHERE info = 'gender' LIMIT 1
    )
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    total_movies DESC;


This SQL query does the following:

1. **Recursive CTE**: It creates a recursive common table expression (`movie_hierarchy`) to find all movies produced from the year 2000 onward and their linked movies hierarchically.

2. **Joins and Aggregations**: It joins several tables like `movie_keyword`, `cast_info`, `name`, and `person_info` to gather more details about each movie’s keywords, cast information, and actor traits (specifically gender).

3. **Conditional Logic**: Utilizes conditional aggregate functions like `COUNT`, `MAX`, `AVG`, and `STRING_AGG` to compute:
   - Total distinct movies per keyword.
   - The latest production year of movies for each keyword.
   - The maximum role order from `cast_info`.
   - The percentage of male actors involved in these movies.
   - A concatenated string of all actor names per keyword.

4. **Predicate Filtering**: The query ensures that only keywords that have more than one movie are included in the final results.

5. **Ordering**: Finally, the results are ordered by the total number of movies associated with each keyword in descending order.

This structure allows for a comprehensive analysis of movie keywords, reflecting on trends in the cast and related production attributes, making it suitable for performance benchmarking scenarios.
