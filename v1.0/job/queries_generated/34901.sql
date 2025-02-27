WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT ah.title) AS actor_movies,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_movie_year,
    AVG(CASE WHEN mc.note IS NULL THEN 0 ELSE 1 END) AS null_note_percentage,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mc.movie_id) DESC) AS movie_rank
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN
    aka_title ah ON mc.movie_id = ah.id
WHERE
    ak.name IS NOT NULL
    AND m.level <= 2
GROUP BY
    ak.name, ak.person_id
HAVING
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY
    total_movies DESC, avg_movie_year DESC
LIMIT 10;

This SQL query utilizes several advanced SQL features including:

1. **Recursive Common Table Expressions (CTEs)** to build a hierarchy of movies linked to each other.
2. **Aggregations** using `GROUP_CONCAT` to concatenate movie titles for an actor.
3. **Calculating metrics** such as total movies and average production year.
4. **Handling NULL values** in computations with a CASE statement.
5. **Window functions** (ROW_NUMBER) to rank actors based on their total movie appearances.
6. **Outer joins** for cases where a movie has no associated companies.
7. **Complex predicates** to filter results, focusing on actors with more than one movie.

The query is structured to provide meaningful insights into the movie relationships and actor contributions while maintaining performance benchmarks through its advanced features.
