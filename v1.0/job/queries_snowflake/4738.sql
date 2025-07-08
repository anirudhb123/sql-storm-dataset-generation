
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS actor_count_rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM
        RankedMovies rm
    WHERE
        rm.actor_count_rank <= 5
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS companies
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    WHERE
        cn.name IS NOT NULL
    GROUP BY
        mc.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'N/A') AS keywords,
    COALESCE(mc.companies, 'N/A') AS production_companies
FROM
    TopMovies tm
LEFT JOIN
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN
    MovieCompanies mc ON tm.movie_id = mc.movie_id
WHERE
    (tm.production_year >= 2000 OR tm.production_year IS NULL)
ORDER BY
    tm.production_year DESC, tm.title;
