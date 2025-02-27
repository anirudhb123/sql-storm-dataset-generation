WITH RECURSIVE ActorMovies AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM cast_info ca
    INNER JOIN title t ON ca.movie_id = t.id
    WHERE ca.person_role_id IN (
        SELECT id FROM role_type WHERE role LIKE '%actor%'
    )
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        cm.linked_movie_id,
        tt.title,
        tt.production_year,
        depth + 1
    FROM ActorMovies am
    JOIN movie_link ml ON am.movie_id = ml.movie_id
    JOIN title tt ON ml.linked_movie_id = tt.id
    JOIN cast_info ca ON tt.id = ca.movie_id
    WHERE ca.person_role_id IN (
        SELECT id FROM role_type WHERE role LIKE '%actor%'
    )
)
SELECT 
    an.name AS actor_name,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    STRING_AGG(DISTINCT tm.title, ', ') AS movies_played_in,
    MAX(t.production_year) AS latest_movie_year,
    ARRAY_AGG(DISTINCT c.kind) AS company_types_involved,
    SUM(CASE 
            WHEN t.production_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10 THEN 1 ELSE 0 
        END) AS recent_movies
FROM ActorMovies am
JOIN aka_name an ON am.person_id = an.person_id
JOIN title t ON am.movie_id = t.id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_type c ON mc.company_type_id = c.id
GROUP BY an.name
HAVING COUNT(DISTINCT am.movie_id) > 5
ORDER BY total_movies DESC
LIMIT 10;

This SQL query accomplishes the following:

1. **Recursive CTE**: It defines a recursive common table expression (CTE) named `ActorMovies` that builds on a base case of movies associated with actors and recursively explores movies linked to these films to capture an extended list of movies featuring those actors.

2. **Window Function**: It aggregates the actor's information by counting distinct movies, using `STRING_AGG` to concatenate movie titles they have acted in, and `ARRAY_AGG` for summarizing different company types they were involved with across films.

3. **Complex Filtering and Aggregation**: The query includes grouping by actor names and filtering to include only those who have acted in more than five distinct movies. Additionally, it counts the number of movies from the last decade to highlight recent contributions.

4. **Nested Subqueries**: It uses nested subquery structures for filtering specific roles within the actors.

5. **Outer Joins**: It employs LEFT JOINs to include company types associated with the movies, ensuring that all actors are included even if no company data is available.

6. **Dynamic Year Calculation**: The use of `EXTRACT` allows the query to dynamically adjust to the current year while counting recent movies.

This query efficiently benchmarks performance by involving complex joins, aggregation, and recursive querying in a way that would put load on the server while still generating insightful results.
