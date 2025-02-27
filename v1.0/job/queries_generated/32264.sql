WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        1 AS level,
        t.production_year
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000 

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        mh.level + 1,
        t.production_year
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),

RankedActors AS (
    SELECT 
        ci.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
)

SELECT 
    mh.title,
    mh.production_year,
    COALESCE(r.name, 'Unknown Actor') AS actor_name,
    mh.level,
    COUNT(DISTINCT r.person_id) AS total_actors,
    STRING_AGG(DISTINCT r.name, ', ') AS actor_list
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    RankedActors r ON ci.person_id = r.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, actor_name, mh.level
HAVING 
    COUNT(DISTINCT r.person_id) > 1 
ORDER BY 
    mh.production_year DESC, mh.level, total_actors DESC;

This SQL query does the following:

1. **CTE (Common Table Expression)**: 
   - `MovieHierarchy` recursively builds a hierarchy of movies produced after 2000, including their titles and production years.
   - `RankedActors` retrieves actors from the `cast_info` table while ranking them per movie in the order of their `nr_order`.

2. **Main SELECT statement**:
   - A `LEFT JOIN` is used to connect the hierarchy of movies with their corresponding cast members.
   - The query uses the `COALESCE` function to handle potential NULL values for the actor names.
   
3. **Aggregations and String Functions**:
   - It counts distinct actors and aggregates their names into a comma-separated list for output.
   
4. **HAVING Clause**:
   - The results are filtered to include only movies with more than one distinct actor.
   
5. **Ordering**: 
   - The final results are ordered by production year in descending order, movie level, and number of actors, enhancing readability and analysis for performance benchmarking.

This query incorporates various concepts like recursive CTEs, window functions, outer joins, aggregate functions, and string handling for a comprehensive performance benchmark scenario.
