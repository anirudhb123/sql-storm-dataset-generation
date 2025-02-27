WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        c.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        ci.movie_id = (SELECT id FROM title WHERE title = 'The Matrix' LIMIT 1)
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        c.name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.person_id
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    STRING_AGG(DISTINCT CASE 
        WHEN LENGTH(a.actor_name) > 10 THEN SUBSTRING(a.actor_name FROM 1 FOR 10) || '...' 
        ELSE a.actor_name 
    END, ', ') AS abbreviated_names,
    COALESCE(MIN(m.production_year), 'N/A') AS first_movie_year,
    COALESCE(MAX(m.production_year), 'N/A') AS last_movie_year,
    AVG(COALESCE(m.production_year, 0)) AS average_movie_year
FROM 
    ActorHierarchy a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    aka_title m ON ci.movie_id = m.movie_id
WHERE 
    a.level <= 2
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT m.id) > 1
ORDER BY 
    movie_count DESC
LIMIT 10;

### Explanation:

1. **Recursive CTE (ActorHierarchy)**:
   - It fetches actors from a specific movie ('The Matrix') and recursively tries to gather their connections through the cast_info table.
   - It establishes a hierarchy of actors participating in the movie and their associated levels.

2. **Main Query**:
   - The main SELECT statement extracts various statistics related to the actors:
     - Actor name (`actor_name`).
     - Count of distinct movies each actor has been associated with.
     - An aggregated string of actor names, abbreviated if longer than 10 characters.
     - The first and last movie years, applying `COALESCE` to handle `NULL` values effectively.
     - Average of the movie years for the actors’ works.

3. **LEFT JOIN**:
   - Uses LEFT JOIN to ensure that if there are actors without any movies in the dataset, they still appear in the result with NULL values in the movie-related fields.

4. **Complicated predicates and expressions**:
   - The use of `STRING_AGG` with a case statement to create a summarized version of the actor names.
   - Various uses of `COALESCE` for `NULL` handling.

5. **HAVING Clause**:
   - Filters the results to only include actors that have more than one distinct movie.

6. **Final limitation**:
   - Limits the output to the top 10 actors based on the count of movies. 

This query is designed to showcase various SQL functionalities while providing meaningful insights into the actor's data within the cinematic universe.
