WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS ranking
    FROM
        aka_title AS t
    LEFT JOIN
        cast_info AS c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),

ActorNameMatch AS (
    SELECT
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        aka_name AS a
    JOIN
        cast_info AS c ON a.person_id = c.person_id
    GROUP BY
        a.name
    HAVING
        COUNT(DISTINCT c.movie_id) > 5
),

FilteredMovies AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM
        RankedMovies AS rm
    WHERE
        rm.actor_count >= 3 AND rm.ranking <= 5
),

PopularMovies AS (
    SELECT
        fm.title,
        fm.production_year,
        fm.actor_count,
        COALESCE(an.movie_count, 0) AS distinct_actor_movie_count
    FROM
        FilteredMovies AS fm
    LEFT JOIN
        ActorNameMatch AS an ON fm.actor_count = an.movie_count
),

FinalOutput AS (
    SELECT
        pm.title,
        pm.production_year,
        pm.actor_count,
        pm.distinct_actor_movie_count,
        CASE
            WHEN pm.distinct_actor_movie_count > 10 THEN 'Highly Acclaimed'
            WHEN pm.distinct_actor_movie_count BETWEEN 5 AND 10 THEN 'Moderately Acclaimed'
            ELSE 'Lesser-known'
        END AS acclaim_status
    FROM
        PopularMovies AS pm
    WHERE
        pm.distinct_actor_movie_count > 0
)

SELECT
    fo.title,
    fo.production_year,
    fo.actor_count,
    fo.acclaim_status
FROM
    FinalOutput AS fo
ORDER BY
    fo.actor_count DESC, fo.production_year ASC;
