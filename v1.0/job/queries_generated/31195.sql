WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS depth
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Only considering movies

    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE
        mh.depth < 5 -- Limit depth to 5 for performance benchmarking
)

SELECT
    a.name AS actor_name,
    m.movie_title,
    COUNT(ci.person_id) AS num_roles,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY COUNT(ci.person_id) DESC) AS role_rank
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN
    keyword k ON k.id = mk.keyword_id
WHERE
    m.production_year >= 2000
    AND m.production_year <= 2023
    AND a.name IS NOT NULL
GROUP BY
    a.name, m.movie_id, m.movie_title, m.production_year
HAVING
    COUNT(ci.person_id) > 1
ORDER BY
    num_roles DESC, m.production_year DESC;

This SQL query performs the following operations:

1. **Common Table Expression (CTE) - Recursive**: The `MovieHierarchy` CTE builds a hierarchy of movies linked together through the `movie_link` table, limiting the depth to 5 levels. It starts with direct movies and follows the links to find related movies.

2. **Joins**: The main query joins the `cast_info` table with the `aka_name` to get actor details and with the `MovieHierarchy` to correlate actors with movies.

3. **Left Joins**: It includes `movie_keyword` and `keyword` tables to aggregate keywords associated with the movies.

4. **Aggregate Functions**: It counts the number of roles an actor has in movies (`num_roles`), calculates the average presence of notes (`has_note`), and concatenates unique keywords into a single string.

5. **Window Function**: It employs the `ROW_NUMBER()` window function to rank the roles of actors within their respective movies.

6. **Filtering and Grouping**: The query filters for movies produced between 2000 and 2023, ensures actor names are not null, and groups results to summarize the data effectively.

7. **Order and Output**: Final results are ordered by the number of roles and movie production year, which provides insights into actor participation trends.
