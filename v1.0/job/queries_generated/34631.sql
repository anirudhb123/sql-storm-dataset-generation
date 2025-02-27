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
        ml.linked_movie_id,
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
    a.id AS actor_id,
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    AVG(extract(year from now()) - mh.production_year) AS avg_age,
    STRING_AGG(DISTINCT at.title, ', ') AS movies_title_list,
    MAX(CASE WHEN ci.note IS NOT NULL THEN 'Has Notes' ELSE 'No Notes' END) AS notes_flag,
    SUM(CASE WHEN ci.role_id IS NULL THEN 1 ELSE 0 END) AS undefined_roles
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = cc.movie_id
JOIN 
    aka_title at ON at.id = cc.movie_id
WHERE 
    a.name IS NOT NULL
    AND (a.name ILIKE '%john%' OR a.name ILIKE '%doe%')
    AND mh.level <= 2
GROUP BY 
    a.id, a.name
ORDER BY 
    movie_count DESC, avg_age ASC
LIMIT 100;

This SQL query performs several complex operations such as:

1. **Recursive CTE (Common Table Expression)**: It builds a hierarchy of movies linked together, allowing the query to traverse multiple generations of linked movies.
  
2. **Left Joins**: Combining data from various tables such as `aka_name`, `cast_info`, `complete_cast`, and `aka_title` while including all records from `aka_name`.
  
3. **Aggregations and Calculations**: It counts the distinct movies an actor has participated in, calculates their average age based on the production year, and concatenates movie titles into a single string.

4. **Conditional Aggregations**: Using `MAX` and `SUM` to derive flags and counts based on specific conditions for notes and roles.

5. **Filter Conditions**: It includes predicates to filter by actor names and the level of movie hierarchy while allowing flexible string matching with `ILIKE`.

6. **Ordering and Limiting Results**: It orders by the count of movies in descending order and the average age in ascending order while limiting the results to the top 100 actors.

This query aims to highlight the performance of complex joins and aggregations over a potentially large dataset while reflecting real-world data inquiries in a movie database context.
