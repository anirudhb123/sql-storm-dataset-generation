WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title AS m
    WHERE
        m.production_year >= 2000 -- Starting point for recent movies

    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link AS ml
    INNER JOIN
        title AS mt ON ml.linked_movie_id = mt.id
    INNER JOIN
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.title, '; ') AS movie_titles,
    AVG(mh.production_year) AS avg_production_year,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS actor_rank
FROM
    aka_name AS ak
JOIN
    cast_info AS ci ON ak.person_id = ci.person_id
LEFT JOIN
    movie_hierarchy AS mh ON ci.movie_id = mh.movie_id
WHERE
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND EXISTS (
        SELECT 1
        FROM role_type AS rt
        WHERE rt.id = ci.role_id
        AND rt.role IN ('Actor', 'Actress')
    )
GROUP BY
    ak.name, ak.person_id
HAVING
    COUNT(DISTINCT mh.movie_id) > 5 -- Only include actors in more than 5 movies
ORDER BY
    total_movies DESC
LIMIT 10;

This SQL query constructs a recursive Common Table Expression (CTE) to traverse through a linked structure of movies, gathering related movie data for films produced after 2000. It joins various tables to gather information about actors, counting the distinct movies they've appeared in and aggregating their titles. It also calculates the average production year of the movies they've acted in. The query filters for valid names, ensures that the actor is indeed a relevant role, and groups by actor to find the top actors by their movie appearances, ultimately ranking them and limiting the result set to the top 10.
