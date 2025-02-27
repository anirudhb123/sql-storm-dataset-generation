WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies
    FROM
        aka_title at
    WHERE
        at.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT
        ak.name AS actor_name,
        ak.id AS actor_id,
        ci.movie_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_rank
    FROM
        aka_name ak
    JOIN
        cast_info ci ON ak.person_id = ci.person_id
),
MoviesWithActorCount AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(ad.actor_id) AS actor_count
    FROM
        RankedMovies rm
    LEFT JOIN
        ActorDetails ad ON rm.movie_id = ad.movie_id
    GROUP BY
        rm.movie_id, rm.title, rm.production_year
),
MoviesWithProductionStats AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.actor_count,
        CASE
            WHEN a.actor_count > 5 THEN 'More than 5 actors'
            WHEN a.actor_count IS NULL THEN 'No actors'
            ELSE '5 or fewer actors'
        END AS actor_count_category
    FROM
        MoviesWithActorCount m
    LEFT JOIN
        (SELECT movie_id, COUNT(*) AS actor_count 
         FROM cast_info 
         GROUP BY movie_id) a ON m.movie_id = a.movie_id
)
SELECT
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.actor_count_category,
    COALESCE(mk.keyword, 'No keywords') AS keyword_info
FROM
    MoviesWithProductionStats mw
LEFT JOIN
    movie_keyword mk ON mw.movie_id = mk.movie_id
WHERE
    (mw.actor_count IS NOT NULL AND mw.actor_count > 0)
    OR (mw.actor_count IS NULL AND EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = mw.movie_id AND mi.info IS NOT NULL))
ORDER BY
    mw.production_year DESC,
    mw.title ASC;

-- Additional part to test unusual semantics and NULL logic
SELECT 
    m.movie_id,
    m.title,
    COALESCE(mi.info, 'N/A') AS movie_info,
    COUNT(DISTINCT ci.person_id) AS distinct_actors
FROM 
    aka_title m
LEFT OUTER JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
GROUP BY 
    m.movie_id, m.title, mi.info
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
    AND mi.info IS NULL
ORDER BY 
    m.title COLLATE "en_US" ASC;

This query utilizes various SQL constructs like CTEs, window functions, outer joins, and complex predicates, showcasing some intricate semantics in SQL. It benchmarks movies by their production year, counts actors, and categorizes them—all while testing the boundaries of null logic and including unusual conditions.
