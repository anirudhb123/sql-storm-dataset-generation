WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM title WHERE production_year = 2020)

    UNION ALL

    SELECT 
        c.person_id,
        a.name,
        ah.depth + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    AVG(m.production_year) AS avg_production_year,
    MAX(m.production_year) AS latest_movie_year,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    ActorHierarchy a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    m.info_type_id IS NOT NULL
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;

-- Optional: Including NULL handling for possible missing keywords
SELECT 
    a.actor_name,
    COALESCE(COUNT(DISTINCT k.keyword), 0) AS keyword_count
FROM 
    ActorHierarchy a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.actor_name
ORDER BY 
    keyword_count DESC
LIMIT 5;

This SQL query constructs two parts using a recursive Common Table Expression (CTE) to build an actor hierarchy based on movies from the year 2020. It incorporates several advanced SQL techniques including joins, aggregates, string functions, null handling, and recursive queries. 

1. The first part gathers actors, their movie counts, and average production years for those who acted in more than 5 movies.
2. The optional second part demonstrates how to count keywords associated with actors with handling of potential NULLs when movies don't have associated keywords. 

Resultantly, these queries are suitable for performance benchmarking due to the complexity and size of the processed data.
