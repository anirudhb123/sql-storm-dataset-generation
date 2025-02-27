
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.id
    GROUP BY
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        RankedMovies
    WHERE
        production_year >= 2000
    LIMIT 10
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        k.keyword
    FROM
        TopMovies m
    JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
),
MovieCompanies AS (
    SELECT
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM
        TopMovies m
    JOIN
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
FinalOutput AS (
    SELECT
        tm.title,
        tm.production_year,
        mk.keyword,
        mc.company_name,
        mc.company_type,
        tm.cast_count
    FROM
        TopMovies tm
    LEFT JOIN
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN
        MovieCompanies mc ON tm.movie_id = mc.movie_id
)
SELECT
    title,
    production_year,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_name || ' (' || company_type || ')', '; ') AS companies,
    cast_count
FROM
    FinalOutput
GROUP BY
    title, production_year, cast_count
ORDER BY
    production_year DESC, cast_count DESC;
