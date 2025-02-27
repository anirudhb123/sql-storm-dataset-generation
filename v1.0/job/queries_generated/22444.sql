WITH RankedMovies AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(at.production_year) ORDER BY COUNT(ci.id) DESC) AS rank,
        COUNT(ci.id) AS cast_count
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.id = ci.movie_id
    WHERE
        at.production_year IS NOT NULL
    GROUP BY
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT
        movie_title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieDetails AS (
    SELECT
        tm.movie_title,
        tm.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM
        TopMovies tm
    LEFT JOIN
        movie_companies mc ON tm.movie_title = (SELECT title FROM aka_title WHERE production_year = tm.production_year)
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        tm.movie_title, tm.production_year
)
SELECT
    md.movie_title,
    md.production_year,
    md.company_count,
    md.companies,
    CASE
        WHEN md.company_count > 5 THEN 'Multiple'
        WHEN md.company_count IS NULL THEN 'No Companies'
        ELSE 'Single'
    END AS company_status,
    COALESCE(SUM(mi.info IS NOT NULL AND mi.info != ''), 0) AS relevant_info_count
FROM
    MovieDetails md
LEFT JOIN
    movie_info mi ON md.movie_title = (SELECT title FROM aka_title WHERE production_year = md.production_year)
GROUP BY
    md.movie_title, md.production_year, md.company_count, md.companies
ORDER BY
    md.production_year DESC, md.company_count DESC;
