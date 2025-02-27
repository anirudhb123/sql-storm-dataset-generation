
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS movie_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, ci.movie_id, rt.role
),
MoviesWithRoles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        pr.person_id,
        pr.role,
        pr.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoles pr ON rm.movie_id = pr.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mwb.movie_id,
    mwb.title,
    mwb.production_year,
    mwb.person_id,
    mwb.role,
    COALESCE(mwb.role_count, 0) AS role_count,
    COALESCE(cd.company_count, 0) AS company_count,
    cd.companies,
    CASE 
        WHEN mwb.role IS NULL THEN 'No Role Assigned'
        ELSE mwb.role 
    END AS role_assignment,
    CASE 
        WHEN COALESCE(mwb.role_count, 0) = 0 THEN 'Role Count Zero'
        ELSE CAST(COALESCE(mwb.role_count, 0) AS VARCHAR)
    END AS role_count_description
FROM 
    MoviesWithRoles mwb
LEFT JOIN 
    CompanyDetails cd ON mwb.movie_id = cd.movie_id
WHERE 
    mwb.title ILIKE '%a%' 
    OR mwb.title ILIKE '%e%' 
    OR mwb.production_year <> 2023  
ORDER BY 
    mwb.production_year DESC, mwb.title ASC
LIMIT 100
OFFSET 0;
