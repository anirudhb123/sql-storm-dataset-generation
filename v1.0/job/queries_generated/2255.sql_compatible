
WITH MovieDetails AS (
    SELECT
        t.title,
        t.production_year,
        c.name AS company_name,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_order
    FROM
        aka_title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    INNER JOIN
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name a ON ci.person_id = a.person_id
    WHERE
        t.production_year >= 2000
        AND c.country_code IS NOT NULL
),
FilteredMovies AS (
    SELECT
        md.title,
        md.production_year,
        md.company_name,
        md.actor_name,
        (SELECT COUNT(*) FROM cast_info ci2 WHERE ci2.movie_id = md.production_year) AS total_cast
    FROM
        MovieDetails md
    WHERE
        md.actor_order <= 3
)
SELECT
    f.title,
    f.production_year,
    f.company_name,
    STRING_AGG(f.actor_name, ', ') AS top_actors,
    f.total_cast
FROM
    FilteredMovies f
GROUP BY
    f.title,
    f.production_year,
    f.company_name,
    f.total_cast
HAVING
    COUNT(f.actor_name) > 1
ORDER BY
    f.production_year DESC,
    f.title;
