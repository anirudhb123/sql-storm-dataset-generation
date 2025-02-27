WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 
ActorsWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS all_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    awr.actor_name,
    awr.role_name,
    cd.company_name,
    cd.company_type,
    mi.all_info
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorsWithRoles awr ON rt.title_id = awr.movie_id AND awr.role_rank = 1
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    rt.rank = 1
ORDER BY 
    rt.production_year DESC, rt.title;
