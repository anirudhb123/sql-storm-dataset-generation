WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN
        aka_title m ON m.id = ml.movie_id
)

SELECT
    ah.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT ac.movie_id) AS total_movies,
    AVG(CASE WHEN cs.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate') THEN pi.info END) AS birthdate
FROM
    aka_name ah
JOIN
    cast_info cs ON ah.person_id = cs.person_id
JOIN
    movie_hierarchy mh ON cs.movie_id = mh.movie_id
JOIN
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN
    person_info pi ON ah.person_id = pi.person_id AND pi.info_type_id IS NOT NULL
WHERE
    ah.name IS NOT NULL
    AND mt.production_year IS NOT NULL 
    AND (kw.keyword LIKE '%action%' OR kw.keyword IS NULL)
GROUP BY
    ah.name,
    mt.title,
    mt.production_year
ORDER BY
    total_movies DESC,
    avg_roles DESC
LIMIT 10;

This SQL query performs the following actions:

1. A recursive Common Table Expression (CTE) named `movie_hierarchy` builds a hierarchy of movies and their linked movies.
2. The main query selects the names of actors alongside their movie titles and production years.
3. It counts the total number of movies per actor and computes the average number of roles they had in movies.
4. It aggregates keywords related to each title and retrieves the actor's birthdate using a correlated subquery.
5. The filter in the WHERE clause ensures the actor names and production years are not NULL, and applies a condition for keywords.
6. Finally, the results are grouped by actor name and movie details, ordered by the total number of movies and average roles, and limited to the top 10 results.
