WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        movie_link ml ON t.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.name AS actor_name,
    t.movie_title,
    t.production_year,
    COUNT(DISTINCT ca.person_id) OVER (PARTITION BY t.id) AS total_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(ca.note, 'No Role') AS role,
    CASE 
        WHEN t.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(t.production_year AS VARCHAR)
    END AS year_description
FROM 
    MovieHierarchy t
LEFT JOIN 
    cast_info ca ON t.movie_id = ca.movie_id
LEFT JOIN 
    aka_name a ON ca.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND (ca.note IS NULL OR ca.note NOT LIKE '%extra%')
GROUP BY 
    a.name, t.movie_id, t.movie_title, t.production_year, ca.note
ORDER BY 
    t.production_year DESC, total_actors DESC
LIMIT 50;

This SQL query uses:
- A recursive common table expression (CTE) to generate a hierarchy of movies from the year 2000 onwards based on linked movies.
- Left joins to associate movie titles with actors and their roles, including keywords.
- Window functions to count the total distinct actors for each movie.
- Conditional expressions to handle NULL values and provide a formatted output.
- Aggregation functions to concatenate keywords for each movie.
- A filtering WHERE clause with complicated logic.
