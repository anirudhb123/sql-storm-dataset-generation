WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
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
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    ac.actor_count,
    cd.company_name,
    cd.company_type,
    COALESCE(NULLIF(rm.title_rank, 0), 'Unranked') AS title_rank_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    (ac.actor_count IS NULL OR ac.actor_count > 5)
    AND (cd.company_type IS NOT NULL OR cd.company_name IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
