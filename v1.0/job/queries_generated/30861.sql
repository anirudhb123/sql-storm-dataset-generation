WITH RECURSIVE CastHierarchy AS (
    -- Base case: Identify top-level movies and their casts
    SELECT 
        c.movie_id,
        a.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE
        c.nr_order = 1  -- Assuming nr_order 1 means primary actor role

    UNION ALL

    -- Recursive case: Fetching additional roles and casting connections
    SELECT 
        m.movie_id,
        a.person_id,
        a.name AS actor_name,
        h.level + 1
    FROM 
        movie_link m
    JOIN CastHierarchy h ON m.movie_id = h.movie_id
    JOIN cast_info c ON m.linked_movie_id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
)
SELECT 
    ch.actor_name,
    COUNT(DISTINCT ch.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    AVG(t.production_year) AS avg_production_year,
    MIN(t.production_year) AS earliest_year,
    MAX(t.production_year) AS latest_year,
    JSON_AGG(DISTINCT ci.note) FILTER (WHERE ci.note IS NOT NULL) AS notes
FROM 
    CastHierarchy ch
JOIN 
    title t ON ch.movie_id = t.id
LEFT JOIN 
    cast_info ci ON ch.movie_id = ci.movie_id AND ch.person_id = ci.person_id
GROUP BY 
    ch.actor_name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 1  -- Only actors with more than one movie
ORDER BY 
    movie_count DESC, earliest_year ASC;  

### Explanation:
1. **Common Table Expression (CTE) with Recursion**: The `CastHierarchy` CTE recursively finds all movies associated with a primary actor. The base case captures the initial movie links and the recursive part pulls in linked movies, building a hierarchy of connections.

2. **Selection and Aggregation**:
   - `COUNT(DISTINCT ch.movie_id)`: Counts the number of unique movies per actor.
   - `STRING_AGG(DISTINCT t.title, ', ')`: Aggregates unique movie titles into a comma-separated string.
   - `AVG`, `MIN`, `MAX`: Computes average, earliest, and latest production years of films the actor has featured in.
   - `JSON_AGG(DISTINCT ci.note)`: Collects unique notes from the `cast_info` table in a JSON array format while filtering out NULL values.

3. **Conditions**: The `HAVING` clause filters out actors listed in only one movie, focusing on those with broader filmographies.

4. **Ordering**: Results are sorted primarily by the number of movies, ensuring that prolific actors appear higher in the results. 

This query is complex, incorporating various SQL concepts like recursion, aggregation functions, JSON manipulation, and conditional logic, making it suitable for performance benchmarking.
