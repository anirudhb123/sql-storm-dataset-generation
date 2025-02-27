WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    ar.actor_count,
    ar.roles,
    mc.companies
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.id = ar.movie_id
FULL OUTER JOIN 
    MovieCompanies mc ON rt.id = mc.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, ar.actor_count DESC, rt.title;
