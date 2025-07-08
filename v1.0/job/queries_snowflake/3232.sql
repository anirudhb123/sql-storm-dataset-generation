
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), ActorRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    ac.unique_roles,
    mci.companies,
    mci.company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoleCounts ac ON rm.title_id = ac.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.title_id = mci.movie_id
WHERE 
    rm.year_rank <= 5
    AND (mci.company_count IS NULL OR mci.company_count > 2)
ORDER BY 
    rm.production_year DESC, ac.actor_count DESC
LIMIT 10;
