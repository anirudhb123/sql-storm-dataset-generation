WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank
    FROM 
        aka_title t
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS num_actors
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(SUM(CASE WHEN cr.role = 'Lead' THEN cr.num_actors ELSE 0 END), 0) AS lead_actor_count,
        COALESCE(SUM(cr.num_actors), 0) AS total_actor_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastRoles cr ON rt.title_id = cr.movie_id
    GROUP BY 
        rt.title_id, rt.title, rt.production_year
)
SELECT
    md.title,
    md.production_year,
    md.lead_actor_count,
    md.total_actor_count,
    COALESCE(mc.company_name, 'Independent') AS producing_company,
    CASE 
        WHEN md.lead_actor_count > 5 THEN 'Blockbuster'
        WHEN md.total_actor_count > 10 THEN 'Ensemble'
        ELSE 'Independent Film'
    END AS film_category
FROM 
    MovieDetails md
LEFT JOIN 
    MovieCompanies mc ON md.title_id = mc.movie_id
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.lead_actor_count DESC;
