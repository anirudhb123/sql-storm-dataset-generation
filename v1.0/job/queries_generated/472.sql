WITH RankedTitles AS (
    SELECT
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year > 2000
),
ActorMovies AS (
    SELECT
        ca.person_id,
        a.name AS actor_name,
        rt.title,
        rt.production_year
    FROM
        cast_info ca
    JOIN
        RankedTitles rt ON ca.movie_id = rt.id
    JOIN
        aka_name a ON ca.person_id = a.person_id
    WHERE
        a.name IS NOT NULL
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
Info AS (
    SELECT
        m.id AS movie_id,
        CASE
            WHEN mi.info IS NULL THEN 'No info available'
            ELSE mi.info
        END AS movie_info
    FROM
        title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT
    am.actor_name,
    am.title,
    am.production_year,
    mk.keywords,
    i.movie_info
FROM
    ActorMovies am
LEFT JOIN
    MovieKeywords mk ON am.title = mk.movie_id
LEFT JOIN
    Info i ON am.title = i.movie_id
WHERE
    am.actor_name NOT LIKE '%Smith%'
ORDER BY
    am.production_year DESC, am.actor_name;
