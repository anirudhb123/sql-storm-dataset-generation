WITH RecursiveTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.nr_order) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, ci.movie_id, rt.role
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ar.role,
    ar.role_count,
    cc.company_count,
    CASE 
        WHEN cc.company_count IS NULL THEN 'No companies associated'
        ELSE 'Companies exist'
    END AS company_status,
    COALESCE(mk.keywords, 'No keywords assigned') AS keywords
FROM 
    RecursiveTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id
LEFT JOIN 
    CompanyCount cc ON rt.title_id = cc.movie_id
LEFT JOIN 
    MovieKeywords mk ON rt.title_id = mk.movie_id
ORDER BY 
    rt.production_year DESC, rt.title;
