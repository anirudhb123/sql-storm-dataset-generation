WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
        
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mh.depth) AS avg_link_depth,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords,
    MAX(EXTRACT(YEAR FROM CURRENT_DATE) - mh.production_year) AS oldest_movie_year,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) > 10 THEN 'Prolific Actor'
        ELSE 'Emerging Actor'
    END AS actor_category
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kt ON mk.keyword_id = kt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    total_movies DESC, actor_name;

This query performs the following tasks:

1. **Recursive CTE**: Constructs a hierarchy of movies and their links starting from productions from the year 2000 onwards.
2. **Aggregations**: Counts the total number of movies associated with each actor, computes the average depth of links between movies, aggregates keywords into a single string for each actor, and calculates the year difference for the oldest movie.
3. **String Aggregation**: Uses `STRING_AGG` to yield a comma-separated list of keywords related to all movies in which an actor has appeared.
4. **CASE statement**: Classifies actors based on their prolific presence in movies.
5. **Filtering and Ordering**: Filters out actors associated with 5 or fewer movies, orders the results first by total movies, and then by actor name. 

This demonstrates complex operations such as joins, CTEs, window functions, aggregate functions, and conditional logic.
