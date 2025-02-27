WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies, including their title and production year
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    
    UNION ALL

    -- Recursive case: Get linked movies for each movie
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
    AVG(mo.info::INTEGER) AS avg_rating,
    MAX(mo.production_year) AS latest_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id
WHERE 
    mo.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 2 
ORDER BY 
    avg_rating DESC, actor_count DESC;
### Explanation:
1. **Recursive Common Table Expression (CTE)**: This part builds a hierarchy of movies, including linked movies, allowing us to retrieve movies in a series or franchise.
2. **Main Query**: The main query fetches data from the `MovieHierarchy` CTE.
3. **Joins**: It performs outer joins to get actor details and movie ratings, pulling in relevant information from `cast_info`, `aka_name`, and `movie_info` tables.
4. **Aggregations**: It aggregates actor counts and actor names for each movie and calculates additional metrics (noted roles and average ratings).
5. **Filtering**: The query only includes movies with more than 2 distinct actors to ensure relevance.
6. **Ordering**: Finally, it orders the results by average rating and actor count for prioritization.

This query could serve well for performance benchmarking in terms of join handling, aggregation efficiency, and overall complexity.
