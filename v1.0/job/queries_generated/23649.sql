WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompleteTitles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        am.actor_count,
        COALESCE(am.actor_count, 0) AS actor_count_filled
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
),
TopMovies AS (
    SELECT 
        ct.*,
        (SELECT AVG(actor_count) FROM ActorMovies) AS avg_actor_count,
        CASE 
            WHEN actor_count_filled > (SELECT AVG(actor_count) FROM ActorMovies) THEN 'Above Average'
            ELSE 'Below Average'
        END AS avg_actor_rating
    FROM 
        CompleteTitles ct
    WHERE 
        rank_per_year <= 3
)
SELECT 
    ct.title,
    ct.production_year,
    ct.actor_count,
    ct.avg_actor_count,
    ct.avg_actor_rating,
    CASE 
        WHEN ct.actor_count IS NULL THEN 'No Actors' 
        WHEN ct.actor_count = 0 THEN 'No Actors' 
        ELSE 'Has Actors' 
    END AS actor_status
FROM 
    TopMovies ct
ORDER BY 
    ct.production_year DESC, 
    ct.title;
