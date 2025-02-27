
WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        COALESCE(STRING_AGG(DISTINCT cn.name, ','), 'No Companies') AS companies
    FROM
        aka_title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT
        c.movie_id,
        STRING_AGG(DISTINCT an.name, ',') AS actors,
        STRING_AGG(DISTINCT rt.role, ',') AS roles,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    JOIN
        aka_name an ON c.person_id = an.person_id
    JOIN
        role_type rt ON c.role_id = rt.id
    GROUP BY
        c.movie_id
),
FinalBenchmark AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.keywords,
        m.companies,
        c.actors,
        c.roles,
        c.actor_count
    FROM
        MovieDetails m
    LEFT JOIN
        CastDetails c ON m.movie_id = c.movie_id
)
SELECT
    *
FROM
    FinalBenchmark
WHERE
    production_year BETWEEN 2000 AND 2023
ORDER BY
    actor_count DESC, title ASC
LIMIT 100;
