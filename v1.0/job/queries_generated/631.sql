WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(t.production_year) ORDER BY t.production_year DESC) AS year_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MoviesWithInfo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        mi.info AS movie_info,
        COALESCE(mk.keyword, 'No Keywords') AS keyword_info
    FROM
        RankedMovies rm
    LEFT JOIN
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    LEFT JOIN
        movie_keyword mk ON rm.movie_id = mk.movie_id
),
TopMovies AS (
    SELECT
        mwi.*,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_cast_order
    FROM
        MoviesWithInfo mwi
    LEFT JOIN
        complete_cast cc ON mwi.movie_id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.id
    WHERE
        mwi.year_rank <= 5
    GROUP BY
        mwi.movie_id, mwi.title, mwi.production_year, mwi.movie_info, mwi.keyword_info
)
SELECT
    tm.title,
    tm.production_year,
    tm.movie_info,
    tm.keyword_info,
    tm.total_cast,
    tm.avg_cast_order,
    fn.name AS main_actor
FROM
    TopMovies tm
LEFT JOIN
    cast_info ci ON tm.movie_id = ci.movie_id AND ci.nr_order = 1
LEFT JOIN
    aka_name fn ON ci.person_id = fn.person_id
WHERE
    fn.name IS NOT NULL
ORDER BY
    tm.production_year DESC, tm.total_cast DESC;
