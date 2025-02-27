WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
ActorNames AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        ac.movie_count
    FROM 
        aka_name ak
    INNER JOIN ActorCounts ac ON ak.person_id = ac.person_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
OuterJoinMovies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        COALESCE(an.movie_count, 0) AS actor_count,
        mi.keywords
    FROM 
        MovieInfo mi
    LEFT JOIN ActorNames an ON mi.movie_id = an.actor_id
)
SELECT 
    o.title,
    o.production_year,
    o.actor_count,
    o.keywords,
    rt.title_id AS top_title_id
FROM 
    OuterJoinMovies o
LEFT JOIN RankedTitles rt ON o.production_year = rt.production_year AND rt.rank = 1
WHERE 
    o.actor_count > 0 OR o.keywords IS NOT NULL
ORDER BY 
    o.production_year DESC, o.actor_count DESC;
