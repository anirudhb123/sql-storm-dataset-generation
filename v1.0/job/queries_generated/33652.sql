WITH RECURSIVE actor_hierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS depth
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name LIKE 'A%'  -- Filter actors with names starting with "A"

    UNION ALL

    SELECT ci.person_id, ci.movie_id, ah.depth + 1
    FROM cast_info ci
    JOIN actor_hierarchy ah ON ci.movie_id = ah.movie_id
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name LIKE 'B%'  -- Extend the hierarchy, finding actor names starting with "B"
)

SELECT 
    an.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    ARRAY_AGG(DISTINCT at.title) AS movies,
    SUM(CASE 
            WHEN at.production_year IS NOT NULL THEN 1 
            ELSE 0 
        END) AS produced_movies,
    AVG(COALESCE(at.production_year, 0)) AS avg_production_year,
    RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
FROM 
    actor_hierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
GROUP BY 
    an.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 1  -- Actors in multiple movies
ORDER BY 
    movie_count DESC,
    actor_name ASC;

### Explanation:
1. **CTE**: A recursive Common Table Expression (`actor_hierarchy`) is used to explore actors recursively. It starts with actors whose names begin with 'A' and finds those they have acted with, who have names starting with 'B', allowing the exploration of a hierarchy or network of actors.

2. **Main Query**: The main query then aggregates results from this hierarchy:
   - **Count of Movies**: Counts the distinct movies each actor has participated in.
   - **Aggregated Movie Titles**: Uses `ARRAY_AGG` to gather all movie titles featuring the actor.
   - **Count of Produced Movies**: Uses a conditional sum to count how many of these movies have a non-null production year.
   - **Average Production Year**: Computes the average production year of the movies an actor has acted in (using `COALESCE` to handle potential NULLs).
   - **Ranking**: Applies a window function to rank actors based on the count of distinct movies.

3. **Filters**: The `HAVING` clause filters for actors who have featured in more than one movie, ensuring only relevant actors are considered.

4. **Order**: Finally, results are ordered by the number of movies in descending order, followed by the actor's name in ascending order.
