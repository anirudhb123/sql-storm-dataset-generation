WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), HighCompanyCount AS (
    SELECT 
        title_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
), ActorRoles AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN r.role LIKE '%lead%' THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
), MovieDetails AS (
    SELECT 
        hm.title_id, 
        hm.title, 
        hm.production_year, 
        ar.actor_count,
        ar.lead_roles
    FROM 
        HighCompanyCount hm
    LEFT JOIN 
        ActorRoles ar ON hm.title_id = ar.movie_id
)

SELECT 
    md.title AS movie_title,
    md.production_year,
    COALESCE(md.actor_count, 0) AS total_actors,
    COALESCE(md.lead_roles, 0) AS total_lead_roles,
    CASE 
        WHEN md.lead_roles > 0 THEN 'Has Lead Roles' 
        ELSE 'No Lead Roles' 
    END AS role_status
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    total_actors DESC
LIMIT 10;
