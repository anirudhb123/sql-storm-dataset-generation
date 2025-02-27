WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.id) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        ci.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
CompanyInfo AS (
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
)
SELECT 
    rt.title,
    rt.production_year,
    ar.name AS actor_name,
    ar.role,
    ci.company_name,
    ci.company_type,
    rt.keyword
FROM 
    RankedTitles rt
JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id AND ar.role_rank = 1
JOIN 
    CompanyInfo ci ON rt.title_id = ci.movie_id
WHERE 
    rt.keyword_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
