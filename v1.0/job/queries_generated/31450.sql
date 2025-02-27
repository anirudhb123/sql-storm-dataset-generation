WITH RECURSIVE ActorTree AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        0 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id = (SELECT id FROM title WHERE title = 'Inception')
    
    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        at.depth + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorTree at ON c.movie_id = at.person_id
)
SELECT 
    DISTINCT at.actor_name,
    COUNT(cm.movie_id) AS movie_count,
    ARRAY_AGG(DISTINCT t.title ORDER BY t.production_year DESC) AS movies
FROM 
    ActorTree at
LEFT JOIN 
    cast_info ci ON at.person_id = ci.person_id
LEFT JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    cn.country_code IS NOT NULL
GROUP BY 
    at.actor_name
HAVING 
    COUNT(ci.movie_id) > 2
ORDER BY 
    movie_count DESC, at.actor_name
LIMIT 10;

This SQL query involves:
- Recursive CTE (`ActorTree`) to build a hierarchy of actors and their connections based on movies.
- LEFT JOINs to combine multiple tables for a comprehensive view of actors and their movie participation.
- COUNT(), ARRAY_AGG() to get specific metrics on the number of movies and to list the movie titles acted in by the specified actors.
- Predicate in the `HAVING` clause to filter actors with more than two movie appearances.
- NULL logic in the WHERE clause to ensure only records with non-null `country_code` are considered.
- Ordering results first by `movie_count` and then by `actor_name`.
