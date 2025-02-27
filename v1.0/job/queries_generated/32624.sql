WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM aka_title mt
    WHERE mt.production_year >= 2000  -- Starting with movies from the year 2000 onwards

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT ch.person_id) AS actor_count,
    AVG(mh.production_year) AS average_production_year,
    ARRAY_AGG(DISTINCT mh.title) AS related_movies
FROM movie_keyword mk
LEFT JOIN movie_info mi ON mk.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')  -- Filter for genre info
LEFT JOIN complete_cast cc ON mk.movie_id = cc.movie_id
LEFT JOIN cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN aka_name ch ON ci.person_id = ch.person_id
LEFT JOIN MovieHierarchy mh ON mk.movie_id = mh.movie_id
WHERE mk.keyword IS NOT NULL
  AND mk.keyword NOT LIKE '%incomplete%'  -- Exclude incomplete keywords
  AND mh.level = 0  -- Consider only top-level movies
GROUP BY mk.keyword
ORDER BY actor_count DESC 
FETCH FIRST 10 ROWS ONLY;  -- Retrieve the top 10 keywords based on actor count
This SQL query does the following:

1. **CTE (Common Table Expression)**: It recursively builds a hierarchy of movies linked together within the `MovieHierarchy`. It starts from movies produced in the year 2000 and goes deeper into linked movies.

2. **Joins**: The query employs various joins:
   - `LEFT JOIN` to connect movie keywords with movie info, cast info, and aka names.
   - It joins with the `MovieHierarchy` to consolidate data about the original movies.

3. **Aggregations**: The query counts unique actors associated with keywords, calculates the average production year of the films, and aggregates related movie titles into an array.

4. **Filtered Conditions**: The query filters out keywords that contain "incomplete" and ensures that only keywords associated with fully linked movies are included.

5. **Ordering and Limiting**: Finally, it orders the results based on the number of actors per keyword and limits the output to the top 10 results.

This elaborate query provides a comprehensive view of how keywords relate to the number of actors in the database and the movies associated with those keywords while leveraging advanced SQL features.
