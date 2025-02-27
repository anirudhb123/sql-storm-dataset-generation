WITH RECURSIVE ActorHierarchy AS (
    -- Base case: select all actors in the cast_info table
    SELECT 
        ci.person_id,
        c.first_name || ' ' || c.last_name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN aka_name c ON ci.person_id = c.person_id
    WHERE 
        c.name IS NOT NULL

    UNION ALL

    -- Recursive case: find all movies this actor has been in
    SELECT 
        ci.person_id,
        c.first_name || ' ' || c.last_name AS actor_name,
        ah.level + 1 AS level
    FROM 
        ActorHierarchy ah
    JOIN cast_info ci ON ah.movie_id = ci.movie_id
    JOIN aka_name c ON ci.person_id = c.person_id
    WHERE 
        c.name IS NOT NULL
)

-- Main Query: select actors with their roles and production years, joined with the corresponding movie titles
SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT t.title) AS movies,
    AVG(t.production_year) AS average_production_year,
    MIN(t.production_year) AS earliest_movie_year,
    MAX(t.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords, 
    STRING_AGG(DISTINCT mk.name, ', ') AS companies
FROM 
    ActorHierarchy a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5 -- Only include actors with more than 5 movies
ORDER BY 
    average_production_year DESC;

This query is intended to benchmark various SQL features, including:

- **Recursive Common Table Expressions (CTEs)** to track the hierarchy of actors across movies.
- A combination of **INNER** and **LEFT JOIN** to gather related movie details and keywords delicately.
- Utilization of **aggregate functions** like `COUNT`, `AVG`, `MIN`, `MAX`, and `STRING_AGG` for summarizing data effectively.
- A **HAVING clause** to filter out only those actors appearing in more than five movies.
- Grouping and ordering capabilities to present a clear and structured output for benchmarking.
