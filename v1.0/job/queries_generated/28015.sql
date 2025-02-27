WITH RankedMovies AS (
    SELECT
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank,
        COUNT(DISTINCT ak.name) OVER (PARTITION BY at.id) AS total_actors
    FROM
        aka_title at
    JOIN
        cast_info ci ON at.id = ci.movie_id
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        at.production_year > 2000
),

ActorStatistics AS (
    SELECT
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS unique_actors,
        AVG(actor_rank) AS average_rank
    FROM
        RankedMovies
    GROUP BY
        movie_title, production_year
),

KeywordStats AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY
        mt.id, mt.title
),

FinalBenchmark AS (
    SELECT
        as.movie_title,
        as.production_year,
        as.unique_actors,
        as.average_rank,
        ks.keyword_count
    FROM
        ActorStatistics as
    JOIN
        KeywordStats ks ON as.movie_title = ks.title
    ORDER BY
        production_year DESC, unique_actors DESC
)

SELECT
    movie_title,
    production_year,
    unique_actors,
    average_rank,
    keyword_count
FROM
    FinalBenchmark
WHERE
    unique_actors > 1 AND
    keyword_count > 0
LIMIT 50;
