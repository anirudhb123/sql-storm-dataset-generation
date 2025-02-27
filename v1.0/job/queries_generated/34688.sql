WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000  -- Limit to movies produced after 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        submt.title,
        submt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title submt ON ml.linked_movie_id = submt.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    SUM(CASE WHEN role.role IS NULL THEN 0 ELSE 1 END) AS speaking_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY SUM(CASE WHEN role.role IS NULL THEN 0 ELSE 1 END) DESC) AS speaking_roles_rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    role_type role ON ci.role_id = role.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL -- Exclude records with NULL actor names
GROUP BY 
    a.name, m.id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 10 -- Include only movies with more than 10 actors
ORDER BY 
    m.production_year DESC,
    speaking_roles DESC;

This SQL query is designed for performance benchmarking and incorporates various SQL constructs:

1. **Recursive CTE** (`MovieHierarchy`) to traverse a movie link structure.
2. **LEFT JOINs** to connect multiple tables while potentially retaining rows without matches.
3. **Aggregate functions** to count distinct actors and sum speaking roles.
4. **String aggregation** (`STRING_AGG`) to collect keywords associated with each movie.
5. Use of **CASE statements** to conditionally sum values.
6. **Window functions** (`ROW_NUMBER`) to rank movies by the number of speaking roles.
7. **Complex predicates** and filtering via the `HAVING` clause to limit results based on actor count.

This query provides insights into movies produced after 2000, detailing the actors, their roles, and additional metadata, ensuring a thorough analysis of the dataset.
