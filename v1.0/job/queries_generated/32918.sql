WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info ca
    WHERE 
        ca.role_id IS NOT NULL

    UNION ALL

    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.person_id <> ah.person_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ah.movie_id) AS movies_count,
    MIN(t.production_year) AS first_appearance,
    MAX(t.production_year) AS last_appearance,
    STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
    SUM(CASE WHEN ca.nr_order IS NULL THEN 0 ELSE 1 END) AS roles_with_order,
    AVG(COALESCE(m.info, 0)) AS average_info_score
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Rating'
    )
LEFT JOIN 
    ActorHierarchy ah ON ah.person_id = a.person_id
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT ah.movie_id) >= 5
ORDER BY 
    movies_count DESC;

### Explanation of SQL Query Components:

1. **Common Table Expression (CTE) - Recursive CTE**: 
    - The CTE `ActorHierarchy` is created to gather all actors and their relationships by movie participation, recursively tracking their roles in movies.
    
2. **SELECT Clause**:
    - Retrieves the actor's name, counts unique movies they've acted in (`movies_count`), and finds the first and last appearance years in movies.
    - The `STRING_AGG` function concatenates the unique titles of movies the actor has appeared in.
    - The count of roles with a defined order is calculated, treating NULLs correctly to ensure accuracy.
    - The average score across any related 'info' (like movie ratings) is calculated safely with `COALESCE`.

3. **JOINs**:
    - Joins the `aka_name`, `cast_info`, `title`, and `movie_info` tables, applying outer joins where relevant to ensure all data is captured about the roles even when some information (like ordering or ratings) may be missing.

4. **HAVING Clause**:
    - Filters to include only actors who have performed in five or more movies.

5. **ORDER BY**:
    - Orders the results by the number of movies in descending order.

This SQL query effectively benchmarks the performance of joins, subqueries, aggregates, and string manipulation, providing insights into actors with notable film careers based on the criteria set.
