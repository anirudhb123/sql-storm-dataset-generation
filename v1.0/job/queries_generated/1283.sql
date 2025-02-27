WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
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
MovieKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY
        mt.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS related_keywords,
    COALESCE(NULLIF(SUM(mci.company_id), 0), 'No companies') AS associated_companies
FROM
    TopMovies tm
LEFT JOIN
    movie_companies mci ON tm.title = (SELECT title FROM aka_title WHERE movie_id = mci.movie_id)
LEFT JOIN
    MovieKeywords mk ON tm.production_year = (SELECT production_year FROM aka_title WHERE movie_id = mk.movie_id)
GROUP BY
    tm.title, tm.production_year, mk.keywords
ORDER BY
    tm.production_year DESC, tm.title;
