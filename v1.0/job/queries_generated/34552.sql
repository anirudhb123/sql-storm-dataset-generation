WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order = 1 -- Fetch leading roles
    GROUP BY 
        c.person_id, a.name
    
    UNION ALL

    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        ah.level + 1 AS level
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info c ON c.movie_id IN (
            SELECT DISTINCT movie_id FROM cast_info WHERE person_id = ah.person_id
        )
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        c.person_id, a.name, ah.level
)
SELECT 
    ah.actor_name,
    ah.level,
    COUNT(DISTINCT da.movie_id) AS movie_count,
    COALESCE(SUM(CASE WHEN t.production_year IS NOT NULL THEN 1 ELSE 0 END), 0) AS valid_movies,
    ARRAY_AGG(DISTINCT t.title) AS titles
FROM 
    ActorHierarchy ah
LEFT JOIN 
    cast_info c ON ah.person_id = c.person_id
LEFT JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    k.keyword IS NOT NULL
    AND ah.level > 1 -- Only for supporting roles
GROUP BY 
    ah.actor_name, ah.level
HAVING 
    COUNT(DISTINCT t.id) > 5 -- Actors with more than 5 unique movies
ORDER BY 
    valid_movies DESC, 
    movie_count ASC;

This SQL query aims to benchmark the performance of various constructs, including:

- A recursive common table expression (CTE) `ActorHierarchy` to build a hierarchy of actors based on their roles in movies.
- Outer joins to combine data from multiple related tables.
- Use of aggregate functions like `STRING_AGG` and `COUNT` to generate summaries of actors and their movies.
- Conditional aggregation with `SUM` and `COALESCE` to handle NULL values in the `production_year`.
- Inclusion of HAVING clause for filtering actors based on specific criteria regarding the number of movies.
- The result is ordered by valid movie counts and movie counts to showcase performance and gather insights based on the criteria set.

This query could be used to analyze actor contributions across various films, providing insights into their roles in cinematic history while testing performance metrics affected by the complexity of joins and aggregations.
