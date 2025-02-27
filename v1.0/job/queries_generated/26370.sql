WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        cast_info c ON c.movie_id = t.id
    GROUP BY
        t.id
),
FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.keyword_count,
        kt.kind AS movie_kind
    FROM
        RankedMovies rm
    JOIN
        kind_type kt ON rm.kind_id = kt.id
    WHERE
        rm.production_year >= 2000 AND
        rm.actor_count > 5
),
TopMovies AS (
    SELECT
        title,
        production_year,
        actor_count,
        keyword_count,
        movie_kind,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, keyword_count DESC) AS rank
    FROM
        FilteredMovies
)
SELECT
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.keyword_count,
    tm.movie_kind
FROM
    TopMovies tm
WHERE
    tm.rank <= 10
ORDER BY
    tm.actor_count DESC, tm.keyword_count DESC;
