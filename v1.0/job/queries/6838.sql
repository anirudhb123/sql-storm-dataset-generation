WITH RankedMovies AS (
    SELECT
        a.title AS movie_title,
        a.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        complete_cast cc ON a.id = cc.movie_id
    JOIN
        cast_info c ON cc.subject_id = c.person_id
    WHERE
        a.production_year IS NOT NULL
    GROUP BY
        a.id, a.title, a.production_year, k.keyword
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        keyword,
        cast_count
    FROM
        RankedMovies
    WHERE
        rank_per_year <= 5
)
SELECT
    tm.movie_title,
    tm.production_year,
    tm.keyword,
    tm.cast_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names
FROM
    TopMovies tm
JOIN
    movie_companies mc ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
JOIN
    company_name cn ON mc.company_id = cn.id
GROUP BY
    tm.movie_title, tm.production_year, tm.keyword, tm.cast_count
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
