
WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_within_year
    FROM
        aka_title mt
    LEFT JOIN
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY
        mt.id, mt.title, mt.production_year
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.avg_order,
        mk.keywords
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    WHERE
        rm.rank_within_year <= 5
)
SELECT
    tm.production_year,
    COUNT(tm.movie_id) AS top_movie_count,
    SUM(tm.cast_count) AS total_cast,
    AVG(tm.avg_order) AS average_order,
    LISTAGG(tm.title || ' (' || tm.keywords || ')', '; ') WITHIN GROUP (ORDER BY tm.title) AS movie_list
FROM
    TopMovies tm
GROUP BY
    tm.production_year
ORDER BY
    tm.production_year DESC;
