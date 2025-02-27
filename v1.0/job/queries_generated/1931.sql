WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mki.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM
        aka_title at
    LEFT JOIN
        movie_companies mc ON at.movie_id = mc.movie_id
    LEFT JOIN
        movie_keyword mki ON at.movie_id = mki.movie_id
    GROUP BY
        at.title, at.production_year
),
TopMovies AS (
    SELECT
        title,
        production_year,
        company_count,
        keyword_count
    FROM
        RankedMovies
    WHERE
        rank <= 5
)
SELECT
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.keyword_count,
    COALESCE(ka.name, 'Unknown') AS actor_name,
    COALESCE(ci.note, 'No role specified') AS role
FROM
    TopMovies tm
LEFT JOIN
    complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE movie_id = cc.movie_id LIMIT 1)
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN
    aka_name ka ON ci.person_id = ka.person_id
WHERE
    tm.company_count > 1
ORDER BY
    tm.production_year DESC, tm.company_count DESC;
