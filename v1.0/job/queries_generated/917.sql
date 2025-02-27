WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'No actors'
        WHEN tm.actor_count < 5 THEN 'Fewer than 5 actors'
        ELSE '5 or more actors'
    END AS actor_category
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC
LIMIT 10;
