
WITH RankedMovies AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER(PARTITION BY at.production_year ORDER BY at.title) AS rank_in_year
    FROM
        aka_title at
    WHERE
        at.production_year >= 2000
),
ActorMovies AS (
    SELECT
        ak.name AS actor_name,
        rm.movie_title,
        rm.production_year,
        COUNT(*) OVER(PARTITION BY ak.id) AS total_movies
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    JOIN
        RankedMovies rm ON ci.movie_id = (SELECT movie_id FROM aka_title WHERE title = rm.movie_title LIMIT 1)
    WHERE
        ak.name IS NOT NULL
),
DistinctActors AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS distinct_movies_count
    FROM
        ActorMovies
    GROUP BY
        actor_name
)
SELECT
    da.actor_name,
    da.distinct_movies_count,
    COALESCE(NULLIF(da.distinct_movies_count, 0), 1) AS safe_divisor,
    ROUND(AVG(TotalMovies.total_movies), 2) AS avg_movies_per_actor
FROM
    DistinctActors da
LEFT JOIN
    ActorMovies TotalMovies ON da.actor_name = TotalMovies.actor_name
GROUP BY
    da.actor_name, da.distinct_movies_count
HAVING
    da.distinct_movies_count > 3
ORDER BY
    da.distinct_movies_count DESC, da.actor_name ASC;
