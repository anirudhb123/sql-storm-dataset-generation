
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank_year
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        COUNT(*) OVER (PARTITION BY ci.person_id) AS total_roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
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
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        pr.person_id,
        pr.role,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoles pr ON rm.movie_id = pr.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    LISTAGG(DISTINCT md.role, ', ') WITHIN GROUP (ORDER BY md.role) AS roles,
    LISTAGG(DISTINCT md.company_name, '; ') WITHIN GROUP (ORDER BY md.company_name) AS companies,
    COUNT(DISTINCT md.person_id) AS total_persons,
    COUNT(md.company_name) FILTER (WHERE md.company_type = 'Distributor') AS distributor_count
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
GROUP BY 
    md.title, md.production_year
HAVING 
    COUNT(DISTINCT md.person_id) > 3
ORDER BY 
    md.production_year DESC, md.title;
