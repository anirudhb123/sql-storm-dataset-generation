WITH RECURSIVE actor_movies AS (
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        ci.person_role_id IS NOT NULL 
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        am.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_title t ON ci.movie_id = t.id
    JOIN 
        actor_movies am ON ci.person_id = am.person_id
    WHERE 
        am.level < 5  -- limiting the recursion to 5 levels
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT am.movie_id) AS movie_count,
    STRING_AGG(DISTINCT am.title, ', ') AS movies,
    MAX(am.production_year) AS latest_year,
    MIN(am.production_year) AS earliest_year,
    AVG((CASE WHEN am.production_year IS NOT NULL THEN am.production_year ELSE NULL END)) AS avg_year,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT am.movie_id) DESC) AS rank
FROM 
    aka_name a
LEFT JOIN 
    actor_movies am ON a.person_id = am.person_id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT am.movie_id) > 5 -- filtering actors with more than 5 movies
ORDER BY 
    movie_count DESC;

This SQL query performs various functions:
1. It uses a recursive CTE to gather movies associated with actors, allowing for a hierarchy of movie appearance up to 5 levels.
2. In the main query, it aggregates results using counts and string functions to collate information about actors and the movies they appeared in.
3. It employs window functions to rank actors based on the number of movies they've been in.
4. It uses conditional aggregation to maintain a robust null handling strategy with average year calculations.
5. It filters results to only include actors who have appeared in more than five movies.
