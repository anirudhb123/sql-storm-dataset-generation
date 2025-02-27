WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM
        aka_title AS t
    JOIN
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN
        cast_info AS ci ON cc.subject_id = ci.person_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY
        t.id
),
MoviesWithKeywords AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        ARRAY_AGG(k.keyword) AS keywords
    FROM
        RankedMovies AS rm
    LEFT JOIN
        movie_keyword AS mk ON rm.movie_id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY
        rm.movie_id
),
TopMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.keywords,
        DENSE_RANK() OVER (ORDER BY m.cast_count DESC) AS rank
    FROM
        MoviesWithKeywords AS m
)
SELECT
    tm.rank,
    tm.title,
    tm.production_year,
    tm.cast_count,
    string_agg(DISTINCT k.keyword, ', ') AS keywords
FROM
    TopMovies AS tm
LEFT JOIN
    unnest(tm.keywords) AS k(keyword)
WHERE
    tm.rank <= 10
GROUP BY
    tm.rank, tm.title, tm.production_year, tm.cast_count
ORDER BY
    tm.rank;
