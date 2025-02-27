WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY
        at.title, at.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year
    FROM
        RankedMovies
    WHERE
        rank <= 5
),
MovieDetails AS (
    SELECT
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ci.note AS role_notes
    FROM
        TopMovies tm
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
    LEFT JOIN
        cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
)
SELECT
    md.title,
    md.production_year,
    md.keyword,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles,
    STRING_AGG(DISTINCT ci.note, ', ') AS all_notes
FROM
    MovieDetails md
LEFT JOIN
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year LIMIT 1)
GROUP BY
    md.title, md.production_year, md.keyword
HAVING
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY
    md.production_year DESC, total_cast DESC;
