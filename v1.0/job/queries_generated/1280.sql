WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.id) AS company_count,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    mcd.company_count,
    mcd.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    (rm.year_rank <= 5 OR ac.actor_count > 10)
ORDER BY 
    rm.production_year DESC, 
    ac.actor_count DESC;
