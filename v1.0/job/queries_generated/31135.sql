WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.level) AS avg_level,
    STRING_AGG(DISTINCT CONCAT(acn.name, ' in ', mh.title), '; ') AS actors_in_movies
FROM 
    MovieHierarchy mh
JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name acn ON ci.person_id = acn.person_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    movie_count DESC;

This query leverages several SQL constructs:

1. **Recursive CTE (Common Table Expression)**: To build a hierarchy of movies linked to one another.
2. **LEFT JOIN**: To connect related datasets, while ensuring all movies are included even if they have no associated casting information.
3. **Aggregation Functions**: To count movies per keyword and get the average movie level.
4. **STRING_AGG**: To concatenate actor names associated with movies.
5. **HAVING Clause**: To filter results based on the aggregated count of distinct movies per keyword.
6. **Complex `WHERE` conditions**: Filtering out records based on certain criteria.

This query gives insights into keywords associated with movies in the hierarchy, counts the number of movies per keyword, and lists actors for those movies.
