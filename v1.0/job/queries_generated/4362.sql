WITH ActorMovies AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM
        ActorMovies
    WHERE
        rn <= 5
),
MovieKeywords AS (
    SELECT DISTINCT
        m.movie_id,
        k.keyword
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
),
KeywordCount AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword) AS keyword_count
    FROM
        MovieKeywords
    GROUP BY
        movie_id
)
SELECT
    tm.actor_id,
    tm.actor_name,
    tm.movie_title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    (SELECT COUNT(*)
     FROM complete_cast cc
     WHERE cc.movie_id = tm.movie_id
       AND cc.status_id IS NULL) AS unknown_status_count
FROM
    TopMovies tm
LEFT JOIN
    KeywordCount kc ON tm.movie_id = kc.movie_id
ORDER BY
    tm.actor_id,
    tm.production_year DESC;
