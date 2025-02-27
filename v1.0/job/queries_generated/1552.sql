WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
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
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    mci.company_names,
    mci.company_types,
    COALESCE(mci.company_names, 'Unknown') AS consolidated_company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.title = (SELECT at.title FROM aka_title at WHERE at.production_year = rm.production_year LIMIT 1)
LEFT JOIN 
    MovieCompanyInfo mci ON rm.production_year = (SELECT at.production_year FROM aka_title at WHERE at.title = rm.title LIMIT 1)
WHERE 
    ac.actor_count > 2 OR mci.company_types IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    ac.actor_count DESC;
