WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(ci.id) AS role_count,
    STRING_AGG(DISTINCT rt.role, ', ') AS roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    a.name IS NOT NULL
    AND m.level <= 2
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(ci.id) > 1
ORDER BY 
    m.production_year DESC, role_count DESC;

-- Performance Benchmarking: Analyzing over multiple joins,
-- aggregate functions, string operations and recursive CTEs

This SQL query constructs a recursive CTE to explore movie hierarchies for linked movies, allowing for a more comprehensive selection of titles. It joins the necessary tables to compile a list of actors, their roles, and the titles of movies produced within a specified hierarchy level. The results are filtered to only include actors who've had multiple roles in the selected movies, allowing for performance benchmarking across various SQL constructs such as outer joins, aggregation, and string functions. The ordering and grouping enhance the clarity of the output.
