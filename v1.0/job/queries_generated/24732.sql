WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieWithCompanies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cs.company_count, 0) AS company_count,
        cs.companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
),
ActorPerformance AS (
    SELECT 
        ai.actor_id,
        ai.actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_with_multiple_roles
    FROM 
        ActorInfo ai
    JOIN 
        cast_info ci ON ai.actor_id = ci.person_id
    GROUP BY 
        ai.actor_id
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1
)
SELECT 
    mwc.movie_id,
    mwc.title,
    mwc.production_year,
    mwc.company_count,
    mwc.companies,
    ap.actor_name,
    ap.movies_with_multiple_roles
FROM 
    MovieWithCompanies mwc
LEFT JOIN 
    ActorPerformance ap ON mwc.movie_id IN (
        SELECT movie_id FROM cast_info WHERE person_id = ap.actor_id
    )
WHERE 
    mwc.company_count > 0
ORDER BY 
    mwc.production_year DESC, mwc.title;

