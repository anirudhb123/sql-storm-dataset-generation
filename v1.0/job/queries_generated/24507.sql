WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND t.production_year IS NOT NULL
    GROUP BY 
        ci.person_id
        
    UNION ALL 
    
    SELECT 
        ah.person_id,
        ah.movies_count + 1,
        ah.titles || ', ' || t.title
    FROM 
        ActorHierarchy ah
    JOIN 
        movie_link ml ON ah.person_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.movie_id
    WHERE 
        t.production_year > 2000 AND ah.movies_count < 5
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    ah.movies_count AS total_movies,
    ah.titles,
    CASE 
        WHEN ah.movies_count IS NULL THEN 'No Movies'
        ELSE 'Active'
    END AS actor_status,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ah.movies_count DESC) AS ranking
FROM 
    aka_name a
LEFT JOIN 
    ActorHierarchy ah ON a.person_id = ah.person_id
WHERE 
    a.name NOT LIKE '%Doe%' 
    AND (ah.movies_count IS NULL OR ah.movies_count > 3)
ORDER BY 
    ah.movies_count DESC;

### Explanation:
1. **CTE (Common Table Expression):** A recursive CTE called `ActorHierarchy` that counts how many movies an actor has been in and collects their titles. It also allows for exploring linked movies via `movie_link`, demonstrating a behavior that revisits the same actors through their film connections up to a certain limit (in this case, less than 5 movies).

2. **STRING_AGG:** It aggregates the titles of movies for each actor, giving a compact view instead of rows.

3. **Conditional Logic:** Uses a `CASE` statement to differentiate between actors who have no movies and those who are active.

4. **Outer Join:** It includes a LEFT JOIN to ensure that all actors are displayed even if they have no entries in the `ActorHierarchy`, which would pull in NULL values that are managed in the final SELECT.

5. **Window Function:** Implements `ROW_NUMBER()` for ranking actors based on their movie count.

6. **Bizarre Semantics:** 
   - Filters actors with a name not like '%Doe%', which is a common surname to simulate filtering out a significant proportion of data.
   - It includes a scenario where if actors have no movies, they get a status of 'No Movies', bypassing the traditional counting methods and leveraging NULL.

7. **Predicates and Expressions:** It combines various conditions like ensuring only movies produced after 2000 are counted, and ensures the count of movies is more than 3, exploring edge cases in filtering and ranking.
