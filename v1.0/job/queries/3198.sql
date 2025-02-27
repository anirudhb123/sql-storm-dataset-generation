WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.person_id, r.role
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
    ar.role,
    ar.role_count,
    mc.company_names
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
WHERE 
    (ar.role_count IS NOT NULL AND ar.role_count > 2) OR (mc.company_names IS NOT NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
