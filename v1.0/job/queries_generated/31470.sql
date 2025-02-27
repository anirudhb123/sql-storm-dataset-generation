WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000

    UNION ALL

    SELECT
        ml.linked_movie_id,
        a.title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN aka_title a ON ml.linked_movie_id = a.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    a.name AS actor_name,
    m.title AS movie_title,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT c.role_id) AS unique_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mi.year) AS avg_production_year
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
JOIN 
    (SELECT 
         movie_id, 
         AVG(production_year) AS year 
     FROM 
         aka_title 
     GROUP BY 
         movie_id) mi ON m.id = mi.movie_id
JOIN
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE
    a.name IS NOT NULL
GROUP BY
    a.name, m.title, mh.level
HAVING
    COUNT(DISTINCT c.role_id) > 2
ORDER BY
    mh.level DESC, unique_roles DESC, a.name;

This SQL query performs several tasks:

1. It uses a recursive Common Table Expression (CTE) to build a movie hierarchy from all movies produced since 2000.
2. Joins the `aka_name`, `cast_info`, `aka_title`, and related tables to pull actor names and their corresponding movie titles.
3. Aggregates the number of unique roles an actor has played and collects all associated keywords for the movies into a single string.
4. It calculates the average production year for the movies that were linked in the hierarchy.
5. Filters out actors who have contributed to more than two distinct roles in the movies.
6. Orders the final result set by the hierarchy level, then by the count of unique roles, and lastly by actor name.
