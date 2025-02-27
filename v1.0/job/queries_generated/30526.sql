WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    a.name AS actor_name,
    count(DISTINCT ch.movie_id) AS movie_count,
    avg(mh.depth) AS average_depth,
    array_agg(DISTINCT kw.keyword) AS associated_keywords,
    CASE 
        WHEN avg(mh.depth) IS NULL THEN 'No Data' 
        ELSE 'Data Available' 
    END as data_availability
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    company_name cn ON ci.movie_id = cn.imdb_id
WHERE 
    a.name IS NOT NULL
    AND cn.country_code IS NOT NULL
    AND mh.production_year >= 2000
GROUP BY 
    a.id
HAVING 
    count(DISTINCT ch.movie_id) > 5
ORDER BY 
    movie_count DESC, 
    average_depth ASC;

This SQL query does several things:
1. **Recursive CTE**: The `MovieHierarchy` recursively finds movies linked to each other, starting from movies released in the year 2000 or later.
2. **Joins**: It joins multiple tables: `aka_name`, `cast_info`, `movie_keyword`, `keyword`, and `company_name` to aggregate information related to the actors and the movies they've participated in.
3. **Aggregations**: It counts the distinct movies an actor has been in and calculates the average depth of links to other movies.
4. **Array Aggregation**: It collects associated keywords into an array.
5. **NULL Logic**: It checks for NULL values in critical fields and provides a message regarding data availability.
6. **HAVING clause**: It filters actors who have been in more than five movies.
7. **Ordering**: Finally, the results are ordered based on the number of movies and average depth.
