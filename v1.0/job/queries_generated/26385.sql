WITH RecursiveCast AS (
    SELECT
        c.movie_id,
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) as actor_order
    FROM
        cast_info c
    JOIN
        aka_name ak ON ak.person_id = c.person_id
    JOIN
        aka_title t ON t.id = c.movie_id
)

SELECT
    rc.movie_id,
    rc.movie_title,
    rc.production_year,
    STRING_AGG(rc.actor_name, ', ' ORDER BY rc.actor_order) AS actor_list
FROM
    RecursiveCast rc
GROUP BY
    rc.movie_id,
    rc.movie_title,
    rc.production_year
HAVING
    COUNT(rc.actor_name) > 5 -- Only return movies with more than 5 actors
ORDER BY
    rc.production_year DESC;
