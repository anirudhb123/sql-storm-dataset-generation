WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000  -- Filter movies from the year 2000 onwards

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE
        m.production_year >= 2000 
)
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    COUNT(ci.role_id) AS roles_count,
    SUM(mi.info_length) AS total_info_length,
    MAX(mi.info) AS longest_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN
    aka_title t ON mh.movie_id = t.id
LEFT JOIN (
    SELECT
        mi.movie_id,
        LENGTH(info) AS info_length
    FROM
        movie_info mi
    WHERE
        info IS NOT NULL
) mi ON t.id = mi.movie_id
WHERE
    a.name IS NOT NULL
GROUP BY
    a.name, t.title
HAVING
    COUNT(ci.role_id) > 1  -- Actors with more than one role
ORDER BY
    roles_count DESC,
    total_info_length DESC;

### Explanation:
1. **Common Table Expression (CTE)**: `MovieHierarchy` uses a recursive CTE to create a hierarchy of movies linked to each other, only including those produced from the year 2000 onwards.

2. **Main Query**:
   - The main SELECT statement pulls data from the `aka_name`, `cast_info`, and the `MovieHierarchy` CTE, joining them with `aka_title` to gather relevant movie titles.
   - A LEFT JOIN on a subquery calculates the lengths of movie info texts, capturing only non-null info.

3. **Aggregations**:
   - The query groups results by actor names and movie titles, counting how many roles each actor has in the context of the filtered movies.
   - Additional aggregates calculate the total length of all info strings for the movies the actor has participated in and finds the longest info string.

4. **Filters**:
   - The HAVING clause ensures that the output only includes actors who have had more than one role.
   - The result set is ordered by the number of roles and the total length of info text.
