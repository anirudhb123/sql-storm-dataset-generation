
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
DirectorCompanies AS (
    SELECT 
        cc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies cc
    JOIN 
        company_name c ON cc.company_id = c.id
    JOIN 
        company_type ct ON cc.company_type_id = ct.id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        dc.company_name,
        dc.company_type,
        ar.actor_name,
        ar.role,
        ar.role_count,
        rm.year_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorCompanies dc ON rm.movie_id = dc.movie_id
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT
    md.title AS Movie_Title,
    md.production_year AS Production_Year,
    md.company_name AS Production_Company,
    md.company_type AS Company_Type,
    md.actor_name AS Actor_Name,
    md.role AS Actor_Role,
    md.role_count AS Number_of_Roles,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')) AS Budget_Info_Count
FROM 
    MovieDetails md
WHERE 
    md.year_rank <= 5
ORDER BY 
    md.production_year DESC, md.title;
