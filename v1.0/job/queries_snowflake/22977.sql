
WITH RankedMovies AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        aka_title a
    LEFT JOIN
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        a.id, a.title, a.production_year
),
ActorCounts AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
MoviesWithActorCounts AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        ac.actor_count,
        COALESCE(ac.actor_count, 0) AS actor_count_null_handling
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE
        rm.keywords IS NOT NULL
        AND rm.year_rank <= 5  
)
SELECT
    mwac.movie_id,
    mwac.title,
    mwac.production_year,
    mwac.actor_count,
    CASE
        WHEN mwac.actor_count IS NULL THEN 'No Actors'
        ELSE 'Has Actors'
    END AS actor_status,
    CASE
        WHEN mwac.production_year < 2000 THEN 'Classic'
        WHEN mwac.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    TRIM(mwac.title) AS trimmed_title
FROM
    MoviesWithActorCounts mwac
WHERE
    mwac.actor_count IS NOT NULL OR mwac.actor_count IS NULL
ORDER BY
    mwac.production_year DESC,
    mwac.actor_count DESC,
    mwac.title;
