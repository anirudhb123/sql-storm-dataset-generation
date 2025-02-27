WITH RECURSIVE ActorHierarchy AS (
    SELECT
        a.id AS actor_id,
        a.person_id,
        a.name,
        NULL::text AS parent_name,
        1 AS level
    FROM
        aka_name a
    WHERE
        a.name IS NOT NULL
    
    UNION ALL
    
    SELECT
        a.id,
        a.person_id,
        a.name,
        ah.name AS parent_name,
        ah.level + 1 AS level
    FROM
        ActorHierarchy ah
    JOIN
        cast_info ci ON ci.person_id = ah.person_id
    JOIN
        aka_name a ON a.person_id = ci.person_id
    WHERE
        ci.nr_order > 1
),

MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON k.id = mk.keyword_id
    GROUP BY
        mk.movie_id
),

SelectedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        nk.keywords
    FROM
        aka_title mt
    LEFT JOIN
        MovieKeywords nk ON nk.movie_id = mt.id
    WHERE
        mt.production_year >= 2000
),

RankedActors AS (
    SELECT
        a.id AS actor_id,
        a.name,
        DENSE_RANK() OVER (PARTITION BY a.name ORDER BY ah.level DESC) AS rank
    FROM
        aka_name a
    LEFT JOIN
        ActorHierarchy ah ON a.person_id = ah.person_id
    WHERE
        a.name IS NOT NULL
),

FinalOutput AS (
    SELECT
        sm.title,
        sm.production_year,
        ra.name AS actor_name,
        ra.rank,
        COALESCE(sm.keywords, 'No Keywords') AS movie_keywords
    FROM
        SelectedMovies sm
    JOIN
        cast_info ci ON ci.movie_id = sm.movie_id
    JOIN
        RankedActors ra ON ra.actor_id = ci.person_id
    WHERE
        ra.rank = 1
)

SELECT
    title,
    production_year,
    actor_name,
    movie_keywords
FROM
    FinalOutput
ORDER BY
    production_year DESC, actor_name;
