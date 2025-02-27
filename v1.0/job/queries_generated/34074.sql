WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id

    UNION ALL

    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        title t ON mh.linked_movie_id = t.id
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    COALESCE(mh.level, 0) AS linkage_level,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS has_info_avg
FROM
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
LEFT JOIN 
    MovieHierarchy mh ON at.movie_id = mh.movie_id 
LEFT JOIN 
    movie_keyword mk ON at.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON at.movie_id = mi.movie_id
WHERE
    at.production_year >= 2000
    AND (a.name IS NOT NULL OR a.name_pcode_cf IS NOT NULL)
GROUP BY
    a.name, t.title, mh.level
HAVING
    COUNT(DISTINCT mk.keyword) > 2
ORDER BY
    linkage_level DESC,
    actor_name ASC;

### Explanation:
- **CTE (Common Table Expression)**: `MovieHierarchy` is a recursive CTE designed to explore the relationships between movies and their linked counterparts.
- **LEFT JOINs**: Various LEFT JOINs are utilized to incorporate related information across multiple tables, ensuring that we capture relevant data even if some movies do not have links.
- **COALESCE**: The `COALESCE` function is used to handle potential NULL values from left joins that establish linkage levels.
- **Aggregate Functions**: COUNT and AVG are used to provide insights into the number of keywords associated with each actor's movies and whether any additional information exists for those movies.
- **Filter Conditions**: The `WHERE` clause filters for movies produced in or after 2000 and ensures actor names are either present or contain specific codes.
- **GROUP BY and HAVING**: The results are aggregated by actor names and movie titles, while the `HAVING` clause ensures that only those with more than 2 distinct keywords are included in the final result, adding complexity to the query.
- **ORDER BY**: Final output is sorted by linkage level in descending order and actor names in ascending order for better readability.
