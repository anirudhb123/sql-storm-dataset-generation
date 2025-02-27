WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
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
    an.name AS actor_name,
    at.title AS movie_title,
    mh.depth AS movie_depth,
    COUNT(kw.id) AS keyword_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(mi.value) FILTER (WHERE mi.info_type_id = 1) AS average_rating
FROM 
    cast_info ci
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
WHERE 
    mh.production_year >= 2000
    AND (ci.note IS NULL OR ci.note <> 'Cameo')
GROUP BY 
    an.name, at.title, mh.depth
ORDER BY 
    movie_depth DESC, actor_name
LIMIT 100;

This SQL query performs the following operations:

1. **Recursive CTE**: It defines a CTE named `MovieHierarchy` to recursively gather all linked movies and their depths based on the relationships found in the `movie_link` table.

2. **Joins**: It joins various tables including `aka_name`, `cast_info`, `movie_keyword`, and `movie_info` to gather detailed information about actors, their movies, related keywords, and any associated ratings.

3. **Aggregations**: It calculates the count of keywords and the average rating (using a filtered aggregate) for each actor-movie combination.

4. **Filtering**: It filters the results to include only movies produced from the year 2000 onwards and excludes any cast members marked as "Cameo".

5. **String Aggregation**: It uses `STRING_AGG` to concatenate distinct keywords associated with each movie.

6. **Ordering and Limit**: Finally, the results are ordered by movie depth in descending order and actor names, limited to the top 100 results.
