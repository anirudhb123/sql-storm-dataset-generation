WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        r.role AS actor_role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
),
CompanyMovies AS (
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
    am.actor_name,
    am.actor_role,
    cm.company_name,
    cm.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies am ON rt.title_id = am.movie_id
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    (rt.rank_per_year <= 10 OR am.actor_role IS NOT NULL)
    AND (cm.company_type IS NOT NULL OR cm.company_name IS NOT NULL)
ORDER BY 
    rt.production_year DESC, 
    rt.title;
