WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    INNER JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    SUM(CASE 
            WHEN c.role_id IS NULL THEN 0 
            ELSE 1 
        END) AS valid_roles,
    ROW_NUMBER() OVER (PARTITION BY mk.keyword ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    mk.keyword IS NOT NULL
    AND mh.production_year IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    avg_production_year DESC, movie_count DESC
LIMIT 10;

This SQL query performs the following tasks:

1. **Recursive Common Table Expression (CTE)**: The `MovieHierarchy` CTE recursively retrieves movies linked to those produced after the year 2000 up to 5 levels of links.

2. **Outer Joins**: Utilizes `LEFT JOIN` operations to include all related keywords, cast information, and actor names, regardless of whether they exist.

3. **Aggregations and Grouping**: It counts distinct movies per keyword, calculates the average production year, and compiles a list of actors involved in those movies.

4. **Complex Conditions**: The `SUM(CASE ...)` statement distinguishes valid roles where a role_id may be NULL, counting only valid actors.

5. **Window Function**: The `ROW_NUMBER()` function ranks keywords based on the count of distinct movies in descending order.

6. **HAVING Clause**: Filters to return only keywords related to more than one movie.

7. **Sorting and Limiting**: The final output is sorted by average production year and movie count, limited to the top 10 results. 

This query serves as a performance benchmark, showcasing multiple SQL constructs effectively.
