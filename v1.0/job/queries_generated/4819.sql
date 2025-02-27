WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    cm.company_names,
    CASE 
        WHEN ac.actor_count IS NULL THEN 'No actors listed'
        ELSE 'Actors available'
    END AS actor_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.title_id = cm.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
