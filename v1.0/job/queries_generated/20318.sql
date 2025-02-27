WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    GROUP BY
        mk.movie_id
),
TopMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        MovieKeywordCounts kc ON m.id = kc.movie_id
    WHERE
        m.production_year = 2023
    ORDER BY
        keyword_count DESC
    LIMIT 10
),
ActorMovieCounts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(a.actor_count, 0) AS actor_count,
        COUNT(DISTINCT mi.id) AS info_type_count
    FROM
        aka_title m
    LEFT JOIN
        ActorMovieCounts a ON m.id = a.movie_id
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    WHERE
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY
        m.id, m.title, a.actor_count
),
FinalRanking AS (
    SELECT
        mt.title,
        mt.production_year,
        mt.actor_count,
        RANK() OVER (ORDER BY mt.actor_count DESC, mt.production_year DESC) AS actor_rank
    FROM
        TopMovies mt
)

SELECT
    fr.title,
    fr.production_year,
    fr.actor_count,
    CASE 
        WHEN fr.actor_count > 10 THEN 'High'
        WHEN fr.actor_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS actor_group,
    COALESCE(NULLIF((SELECT AVG(actor_count) FROM MovieInfo), 0), 1) AS adjustment_factor,
    fr.actor_count / COALESCE(NULLIF((SELECT AVG(actor_count) FROM MovieInfo), 0), 1) AS normalized_actor_count
FROM
    FinalRanking fr
WHERE
    fr.actor_rank <= 5
ORDER BY
    fr.actor_count DESC;
