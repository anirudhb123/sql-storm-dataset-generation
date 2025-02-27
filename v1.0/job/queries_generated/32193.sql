WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM aka_title WHERE title ILIKE '%Mystery%')
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.nr_order > 0
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    AVG(m.production_year) AS avg_production_year,
    MAX(m.production_year) AS latest_movie_year,
    MIN(m.production_year) AS earliest_movie_year,
    CASE
        WHEN COUNT(DISTINCT c.movie_id) > 5 THEN 'Established Actor'
        ELSE 'Newcomer'
    END AS actor_status
FROM 
    actor_hierarchy ah
JOIN 
    cast_info c ON ah.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    title m ON m.id = c.movie_id
GROUP BY 
    a.actor_name
ORDER BY 
    movie_count DESC
LIMIT 10;

### Explanation of the Query:

1. **Recursive CTE (Common Table Expression)**: The `actor_hierarchy` CTE is defined to recursively gather all actors who have contributed to movies with the title containing 'Mystery'. It starts with the movies and proceeds to potentially include additional levels of cast members as needed.

2. **Main Selection**: The main query selects actor names and computes various metrics, including:
   - `COUNT(DISTINCT c.movie_id)`: Counts the unique movies participated in by the actor.
   - `STRING_AGG(DISTINCT t.title, ', ')`: Aggregates titles of movies into a single string.
   - `AVG(m.production_year)`, `MAX(m.production_year)`, and `MIN(m.production_year)`: These functions compute the average, latest, and earliest production year of films associated with each actor.

3. **Actor Status**: A derived column `actor_status` categorizes actors based on their movie count to distinguish between established actors and newcomers.

4. **Final Filtering & Ordering**: The final selection limits the results to the top 10 actors based on the count of movies they have participated in.

This query showcases advanced SQL constructs such as recursive CTEs, window functions, nested subqueries, string aggregation, and conditional logic, demonstrating an intricate analysis with potential performance benchmarking capabilities.
