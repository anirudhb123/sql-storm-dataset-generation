WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
    UNION ALL
    SELECT 
        linked_movie.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link linked_movie ON mh.movie_id = linked_movie.movie_id
    JOIN 
        aka_title mt ON linked_movie.linked_movie_id = mt.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year AS year,
    ci.nr_order AS role_order,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year DESC) AS role_rank,
    COALESCE(pi.info, 'No info') AS person_info,
    COUNT(*) OVER (PARTITION BY mt.id) AS total_cast,
    (SELECT COUNT(DISTINCT mc.id)
     FROM movie_companies mc
     WHERE mc.movie_id = mt.id) AS total_companies
FROM 
    cast_info ci
INNER JOIN
    aka_name ak ON ci.person_id = ak.person_id
INNER JOIN 
    MovieHierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    ak.name IS NOT NULL
    AND (mt.production_year IS NOT NULL OR mt.production_year > 2005)
ORDER BY 
    mt.production_year DESC, 
    role_rank ASC
FETCH FIRST 100 ROWS ONLY;

This query performs the following operations:

1. **CTE (Common Table Expression)**: It creates a recursive CTE to build a hierarchy of movies (considering links between movies) to fetch movies produced between 2000 and 2020.

2. **Joining Tables**: It joins the `cast_info`, `aka_name`, and movies from the recursive CTE to get the names of actors and corresponding movies.

3. **Window Functions**: It uses `ROW_NUMBER()` to rank the roles of actors based on their production years and counts the total number of cast members per movie using `COUNT(*) OVER`.

4. **Subqueries**: It employs a subquery to get the total companies involved in each movie.

5. **COALESCE**: It provides a fallback with `COALESCE` for when there is no biography information.

6. **Complicated WHERE Clauses**: It filters for valid actor names and ensures production years meet specified conditions.

7. **Sorting**: Finally, it orders the results by production year in descending order and role rank for better readability and understanding.

8. **Limiting Results**: It fetches only the first 100 rows for performance optimization.
