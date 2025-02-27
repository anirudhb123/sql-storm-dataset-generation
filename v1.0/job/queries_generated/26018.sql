WITH MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    WHERE
        m.production_year >= 2000
    GROUP BY
        m.id, m.title, m.production_year
    HAVING
        COUNT(DISTINCT k.id) > 2  -- At least 3 distinct keywords
),

TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        keywords,
        companies,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM
        MovieDetails
)

SELECT
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keywords,
    tm.companies
FROM
    TopMovies tm
WHERE
    tm.rank <= 10  -- Top 10 movies by cast count
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
