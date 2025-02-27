WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.imdb_index,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT
        r.movie_id,
        r.title,
        r.production_year
    FROM
        RankedMovies r
    WHERE
        r.rank <= 10
),
ActorMovieInfo AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        p.info AS actor_info
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        person_info p ON c.person_id = p.person_id
    WHERE
        c.note IS NULL
),
MovieKeywordInfo AS (
    SELECT
        m.movie_id,
        k.keyword AS movie_keyword
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
),
FinalReport AS (
    SELECT
        tm.title,
        tm.production_year,
        am.actor_name,
        am.actor_info,
        mk.movie_keyword
    FROM
        TopMovies tm
    LEFT JOIN
        ActorMovieInfo am ON tm.movie_id = am.movie_id
    LEFT JOIN
        MovieKeywordInfo mk ON tm.movie_id = mk.movie_id
)
SELECT
    title,
    production_year,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
FROM
    FinalReport
GROUP BY
    title, production_year
ORDER BY
    production_year DESC, title;
