WITH RankedMovies AS (
    SELECT
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        a.name IS NOT NULL
),
MovieCompanies AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies m
    JOIN
        company_name c ON m.company_id = c.id
    JOIN
        company_type ct ON m.company_type_id = ct.id
),
KeywordInfo AS (
    SELECT
        mk.movie_id,
        k.keyword
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
)
SELECT
    r.actor_name,
    r.movie_title,
    r.production_year,
    mc.company_name,
    mc.company_type,
    ki.keyword
FROM
    RankedMovies r
LEFT JOIN
    MovieCompanies mc ON r.movie_title = mc.movie_id
LEFT JOIN
    KeywordInfo ki ON r.movie_title = ki.movie_id
WHERE
    r.rank <= 10
ORDER BY
    r.production_year DESC, r.actor_name, r.movie_title;
