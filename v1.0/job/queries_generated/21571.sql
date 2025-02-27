WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT kc.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%')
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        c.person_role_id IS NOT NULL 
        AND c.nr_order IS NOT NULL
    GROUP BY 
        c.movie_id, a.name
),
MoviesWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        am.actor_name,
        am.keywords,
        am.total_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
),
NullLogicExample AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.production_year,
        mw.title_rank,
        mw.actor_name,
        coalesce(CAST(mw.keywords AS text), 'No Keywords') AS keywords,
        NULLIF(mw.total_actors, 0) AS actor_count
    FROM 
        MoviesWithInfo mw
)
SELECT 
    nle.movie_id, 
    nle.title, 
    nle.production_year, 
    nle.title_rank,
    nle.actor_name,
    CASE 
        WHEN nle.actor_count IS NULL THEN 'No Actors Available'
        ELSE nle.actor_count::text
    END AS actor_count_display
FROM 
    NullLogicExample nle
WHERE 
    nle.title_rank = 1 
ORDER BY 
    nle.production_year DESC, nle.title ASC;

-- Potential actions to benchmark performance on various constructs
-- Attempting to analyze performance by running EXPLAIN ANALYZE on the above query and observing the execution plan.
