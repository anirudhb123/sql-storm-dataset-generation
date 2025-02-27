WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t 
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        SUM(CASE WHEN ct.kind = 'production' THEN 1 ELSE 0 END) AS production_count
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
    rt.title,
    rt.production_year,
    COALESCE(ar.name, 'N/A') AS actor_name,
    COALESCE(ar.role, 'N/A') AS role,
    COALESCE(mc.company_names, 'No Companies') AS companies,
    mc.production_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id AND ar.actor_order = 1
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
WHERE 
    rt.rank <= 10
ORDER BY 
    rt.production_year DESC, rt.title;
