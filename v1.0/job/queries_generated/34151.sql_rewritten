WITH RECURSIVE movies_with_cast AS (
    SELECT
        a.id AS aka_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM
        aka_name AS a
    JOIN
        cast_info AS c ON a.person_id = c.person_id
    JOIN
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE
        t.production_year >= 2000
)
SELECT
    movie_id,
    title,
    production_year,
    STRING_AGG(actor_name, ', ') AS actor_list
FROM
    movies_with_cast
GROUP BY
    movie_id, title, production_year
HAVING
    COUNT(*) > 3
ORDER BY
    production_year DESC;