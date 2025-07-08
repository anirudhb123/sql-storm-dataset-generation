
WITH FilteredMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        aka_title t
    JOIN
        movie_keyword mk ON t.id = mk.movie_id
    JOIN
        keyword kc ON mk.keyword_id = kc.id
    WHERE
        t.production_year >= 2000 AND
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS keyword_rank
    FROM
        FilteredMovies
),

CostarCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS costar_count
    FROM
        cast_info c
    JOIN
        TopMovies tm ON c.movie_id = tm.movie_id
    GROUP BY
        c.movie_id
)

SELECT
    tm.title,
    tm.production_year,
    tc.costar_count,
    tm.keyword_count
FROM
    TopMovies tm
JOIN
    CostarCount tc ON tm.movie_id = tc.movie_id
WHERE
    tm.keyword_rank <= 10
ORDER BY
    tm.keyword_count DESC, 
    tc.costar_count DESC;
