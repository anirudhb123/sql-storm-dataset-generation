
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS row_num
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.production_year >= 2000
),

MovieCast AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM
        cast_info c
    JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        c.movie_id
),

MoviesByKeyword AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        mc.cast_count,
        mc.cast_names
    FROM
        RankedMovies rm
    LEFT JOIN
        MovieCast mc ON rm.movie_id = mc.movie_id
    WHERE
        rm.row_num = 1
),

FinalBenchmark AS (
    SELECT
        mbk.movie_id,
        mbk.movie_title,
        mbk.production_year,
        mbk.cast_count,
        mbk.cast_names,
        COUNT(DISTINCT mi.info) AS info_count
    FROM
        MoviesByKeyword mbk
    LEFT JOIN
        movie_info mi ON mbk.movie_id = mi.movie_id
    GROUP BY
        mbk.movie_id, mbk.movie_title, mbk.production_year, mbk.cast_count, mbk.cast_names
)

SELECT
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.cast_count,
    fb.cast_names,
    fb.info_count
FROM
    FinalBenchmark fb
ORDER BY
    fb.production_year DESC, fb.cast_count DESC;
