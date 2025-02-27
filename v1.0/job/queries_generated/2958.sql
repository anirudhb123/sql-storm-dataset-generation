WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorMovieCounts AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    LEFT JOIN
        movie_companies mc ON ci.movie_id = mc.movie_id
    GROUP BY
        ci.person_id
),
TopActors AS (
    SELECT
        ak.name,
        a.movie_count
    FROM
        aka_name ak
    JOIN
        ActorMovieCounts a ON ak.person_id = a.person_id
    WHERE
        a.movie_count >= 5
),
MovieInfo AS (
    SELECT
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_snippet
    FROM
        movie_info mi
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'plot')
    GROUP BY
        mi.movie_id
)
SELECT
    rm.title,
    rm.production_year,
    ta.name AS top_actor,
    COALESCE(mi.info_snippet, 'No Info Available') AS movie_info
FROM
    RankedMovies rm
LEFT JOIN
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN
    TopActors ta ON ci.person_id = ta.person_id
LEFT JOIN
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE
    rm.rn <= 10
ORDER BY
    rm.production_year DESC, rm.title;
