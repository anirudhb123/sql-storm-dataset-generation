WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.movie_id AS parent_id,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT
    h.movie_id,
    h.title,
    h.production_year,
    h.depth,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_collected
FROM
    MovieHierarchy h
LEFT JOIN
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = h.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_info mi ON h.movie_id = mi.movie_id 
WHERE
    h.production_year > 2000
    AND (h.depth IS NULL OR h.depth <= 2)
GROUP BY
    h.movie_id, h.title, h.production_year, h.depth
HAVING
    COUNT(DISTINCT cc.person_id) > 0
ORDER BY
    h.production_year DESC, h.title;

This SQL query does the following:

1. **Recursive CTE**: The `MovieHierarchy` CTE recursively builds a hierarchy of movies by retrieving the movie titles and their linked movies (up to 2 levels deep).
  
2. **Complex Joins**: Joins are made on various tables including `complete_cast`, `cast_info`, `aka_name`, and `movie_info` to gather movie and actor details.

3. **Aggregations**: It aggregates the number of distinct cast members (`total_cast`), concatenates actor names into a single string (`actors`), and calculates the average of info collected.

4. **Filtering**: Applies filters to ensure only movies produced after the year 2000 and within a certain depth are considered.

5. **Group by and Order**: The results are grouped by movie details and ordered by production year in descending order followed by title.
