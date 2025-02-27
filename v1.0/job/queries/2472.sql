WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyMovieCounts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
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
HighCountMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cmc.company_count, 0) AS company_count,
        COALESCE(amc.actor_count, 0) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyMovieCounts cmc ON rm.movie_id = cmc.movie_id
    LEFT JOIN 
        ActorMovieCounts amc ON rm.movie_id = amc.movie_id
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.company_count,
    h.actor_count,
    CASE 
        WHEN h.company_count > 5 THEN 'Many Companies'
        WHEN h.company_count IS NULL THEN 'No Companies'
        ELSE 'Few Companies'
    END AS company_status,
    CASE 
        WHEN h.actor_count > 10 THEN 'Star-studded'
        WHEN h.actor_count IS NULL THEN 'No Actors'
        ELSE 'Few Actors'
    END AS actor_status
FROM 
    HighCountMovies h
WHERE 
    h.company_count > 0 OR h.actor_count > 0
ORDER BY 
    h.production_year DESC, h.actor_count DESC;
