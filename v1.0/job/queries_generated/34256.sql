WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS parent_movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.title AS parent_movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    COUNT(DISTINCT cc.role_id) AS role_count,
    AVG(mv.level) AS avg_link_level,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    cast_info cc
JOIN 
    aka_name ak ON cc.person_id = ak.person_id
JOIN 
    title mv ON cc.movie_id = mv.id
LEFT JOIN 
    movie_keyword mk ON mv.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy mh ON mv.id = mh.movie_id
WHERE 
    mv.production_year > 2000
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT cc.role_id) > 1
ORDER BY 
    role_count DESC, mv.production_year DESC
LIMIT 100;

### Explanation of Construct Used in the Query:
1. **Recursive CTE (`MovieHierarchy`)**: This section creates a hierarchy of movies based on the links between them, which is useful for exploring affiliations among films.
2. **JOINs**: The main query joins `cast_info` with `aka_name`, `title`, and other relevant tables to get details about actors and movies.
3. **LEFT JOIN**: This is used to bring in potential keywords associated with each movie, even if no keywords exist (hence possible NULLs).
4. **Aggregations**: `COUNT(DISTINCT cc.role_id)` aggregates the unique roles an actor has, while `AVG(mv.level)` provides insights into the average link depth of movies connected to the selected titles.
5. **String Aggregation (`STRING_AGG`)**: This collects keywords into a single string for easier reading.
6. **Complicated Predicates**: The query filters for movies produced after 2000 and ensures that actor names are not NULL.
7. **`HAVING` Clause**: Filters groups based on an aggregate condition, ensuring only actors with more than one role are counted.
8. **Ordering**: Results are ordered by the number of unique roles and then by production year, showcasing the most active actors in the recent cinematic landscape.

