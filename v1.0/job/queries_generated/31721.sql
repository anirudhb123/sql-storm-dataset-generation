WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        ct.kind AS role,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM movie_info WHERE info LIKE '%blockbuster%')  -- Base case: Actors from blockbuster movies

    UNION ALL

    SELECT 
        c.person_id,
        ct.kind,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id IN (SELECT linked_movie_id FROM movie_link WHERE movie_id = ah.actor_id)
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    WHERE 
        ah.level < 3  -- Limit the depth of hierarchy to 3 levels
)

SELECT 
    a.actor_id,
    ak.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    MAX(CASE WHEN t.production_year IS NULL THEN 'Unknown' ELSE CAST(t.production_year AS TEXT) END) AS last_known_year,
    ROW_NUMBER() OVER (PARTITION BY a.actor_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
FROM 
    ActorHierarchy a
JOIN 
    aka_name ak ON a.actor_id = ak.person_id
JOIN 
    cast_info c ON a.actor_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
GROUP BY 
    a.actor_id, ak.name
HAVING 
    COUNT(DISTINCT c.movie_id) >= 3  -- Only include actors with 3 or more movies
ORDER BY 
    rank
LIMIT 10;  -- Return top 10 actors based on movies count

### Explanation:
1. **CTE (Common Table Expression)**: A recursive CTE `ActorHierarchy` builds a hierarchy of actors associated with blockbuster movies and their linked movies. It starts with actors from blockbuster movies and recursively finds other movies they are linked to (up to 3 levels deep).

2. **Aggregating Data**: The main SELECT statement aggregates data for each actor: the number of distinct movies, movie titles, and last known production years. 
   
3. **Window Function**: It uses `ROW_NUMBER()` to rank actors based on the number of movies they have been involved in.

4. **HAVING Clause**: Ensures only actors involved in three or more distinct movies are included.

5. **String Aggregation**: `STRING_AGG()` is used to concatenate movie titles into a single string, enhancing readability.

6. **NULL Logic**: Handles cases where the production year may be NULL by providing a default value of 'Unknown'.

7. **Final Sorting and Limiting**: The final output is sorted by rank and limited to the top 10 actors based on their movie count.
