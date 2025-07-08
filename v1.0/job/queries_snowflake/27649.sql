
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title a
    JOIN
        cast_info ci ON a.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        a.id, a.title, a.production_year, a.kind_id
),
TopRatedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.actors
    FROM
        RankedMovies rm
    WHERE
        rm.rank <= 10
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    kt.kind AS movie_kind,
    rm.cast_count,
    rm.actors
FROM
    TopRatedMovies rm
JOIN
    kind_type kt ON rm.kind_id = kt.id
ORDER BY
    rm.production_year DESC, rm.cast_count DESC;
