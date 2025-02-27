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
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.id AS person_id,
    a.name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
    ARRAY_AGG(DISTINCT CONCAT(mh.title, ' (', mh.production_year, ')')) AS linked_movies,
    RANK() OVER (PARTITION BY a.id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    actor_rank, movie_count DESC;

### Explanation:
1. **Recursive CTE `MovieHierarchy`**: This common table expression generates a hierarchy of movies linked to titles produced after the year 2000. It recursively retrieves movies that link to each other through the `movie_link` table.

2. **Main Query**: We select actor details from `aka_name` and join the `cast_info` to get the movie participation. We further link to the `MovieHierarchy` to retrieve additional movie titles associated with the actors.

3. **Aggregations**:
   - `COUNT(DISTINCT c.movie_id)` counts the unique movies the actor is involved with.
   - `SUM(CASE ...)` counts how many movies have notes.

4. **Array Aggregation**: This collects all linked movie titles and their production years into an array, providing a clear view of the movie connections.

5. **Ranking with `RANK()`**: Actors are ranked based on their movie count, allowing for subsequent analysis of their performance.

6. **Filtering**: The `HAVING` clause ensures that only those actors with more than 5 movies are included in the results.

7. **Ordering**: Results are ordered first by rank and then by movie count, providing an easy way to find the top actors based on their linked movies.

This query is complex, incorporating features like outer joins, recursive CTEs, window functions, and conditional aggregations, making it suitable for performance benchmarking in SQL.
