WITH RECURSIVE MovieGraph AS (
    SELECT 
        c.movie_id,
        t.title,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order,
        0 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year >= 2000
      AND a.name IS NOT NULL
    
    UNION ALL

    SELECT 
        mg.movie_id,
        t.title,
        c.person_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mg.movie_id ORDER BY a.name) AS actor_order,
        mg.depth + 1
    FROM MovieGraph mg
    JOIN cast_info c ON c.movie_id = (
        SELECT linked_movie_id
        FROM movie_link ml
        WHERE ml.movie_id = mg.movie_id
        AND ml.link_type_id = 1 -- only considering 'sequel' type links
        LIMIT 1
    )
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year >= 2000
      AND a.name IS NOT NULL
)

SELECT 
    g.movie_id,
    g.title,
    STRING_AGG(g.actor_name, ', ') AS actor_names,
    COUNT(*) AS total_actors,
    MAX(g.actor_order) AS max_actor_order,
    MIN(g.depth) AS min_depth,
    CASE 
        WHEN COUNT(*) > 10 THEN 'Large Cast'
        WHEN COUNT(*) BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM MovieGraph g
GROUP BY g.movie_id, g.title
HAVING MAX(g.actor_order) < 20
AND MIN(g.depth) <= 2
ORDER BY total_actors DESC, g.title ASC
LIMIT 100
OFFSET 0;

### Explanation:
1. **Common Table Expression (CTE)**: A recursive CTE called `MovieGraph` is defined to create a graph of movies and their casts. The first part of the CTE gathers the basic information of movies with a production year since 2000 and their associated actors.
   
2. **Recursive Query**: The second part of the CTE recursively finds sequels to those movies, expanding the depth of the query to include sequels as long as they are direct (based on link type id).

3. **Window Function**: Within the CTE, we utilize `ROW_NUMBER()` to establish an order for each actor in the movie.

4. **Aggregation**: The final query aggregates results to provide the `string_agg` with a count of the actors, maximum order, and minimum depth for movies found.

5. **Conditional Logic**: A `CASE` statement evaluates the total number of actors in order to categorize the size of the cast.

6. **Exclusions**: The `HAVING` clause limits results where the maximum actor order exceeds 20 and the minimum depth is greater than 2.

7. **Sorting and Limiting**: Finally, the results are ordered by the total number of actors in descending order and titles in ascending order, with pagination included through `LIMIT` and `OFFSET`.

This query showcases complex SQL constructs, including recursive CTEs, window functions, aggregate functions, and nuanced filter logic to provide insights on movie casts over a span of years.
