WITH RankedTitles AS (
    SELECT 
        at.movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ak.name, ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ai.actor_name,
    ai.role_count,
    cd.company_names
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorInfo ai ON rt.movie_id = ai.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.movie_id = cd.movie_id
WHERE 
    rt.year_rank <= 5 
    AND (ai.role_count IS NULL OR ai.role_count > 1)
ORDER BY 
    rt.production_year DESC, 
    ai.role_count DESC NULLS LAST;
