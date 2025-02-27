WITH RankedMovies AS (
    SELECT
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM
        aka_title mt
    LEFT JOIN
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        total_cast
    FROM
        RankedMovies
    WHERE
        rank_by_cast <= 5
)
SELECT
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(SUM(mk.keyword_id), 0) AS total_keywords
FROM
    TopMovies tm
LEFT JOIN
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year)
LEFT JOIN
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title AND production_year = tm.production_year)
GROUP BY
    tm.movie_title, tm.production_year, tm.total_cast
ORDER BY
    tm.total_cast DESC, tm.production_year ASC;
