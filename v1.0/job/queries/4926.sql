WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(cmc.company_count, 0) AS company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    CompanyMovieCounts cmc ON rm.title_id = cmc.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC,
    actor_count DESC,
    company_count DESC;
