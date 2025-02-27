WITH MovieRoles AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        c.nr_order AS cast_order,
        r.role AS role_name
    FROM
        cast_info c
    INNER JOIN aka_name a ON c.person_id = a.person_id
    INNER JOIN title t ON c.movie_id = t.id
    INNER JOIN role_type r ON c.role_id = r.id
    WHERE
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
RankedMovies AS (
    SELECT
        actor_name,
        movie_title,
        cast_order,
        role_name,
        ROW_NUMBER() OVER (PARTITION BY actor_name ORDER BY cast_order) AS rn
    FROM
        MovieRoles
)
SELECT
    r.actor_name,
    STRING_AGG(r.movie_title, ', ') AS movies,
    COUNT(DISTINCT r.movie_title) AS movie_count,
    MAX(r.cast_order) AS max_order,
    CASE
        WHEN COUNT(DISTINCT r.movie_title) > 5 THEN 'Prolific Actor'
        ELSE 'Emerging Talent'
    END AS actor_status
FROM
    RankedMovies r
GROUP BY
    r.actor_name
HAVING
    MAX(r.cast_order) > 2
ORDER BY
    movie_count DESC;