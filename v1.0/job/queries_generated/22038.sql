WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        ci.*,
        rt.role AS role_name,
        CASE 
            WHEN ci.person_role_id IS NULL THEN 'Unknown Role'
            ELSE rt.role
        END AS safe_role
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieCompaniesInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CorrelatedSubquery AS (
    SELECT 
        title_id,
        (SELECT COUNT(*) 
         FROM MovieCompaniesInfo mci 
         WHERE mci.movie_id = rm.title_id) AS associated_companies
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank = 1
),
FinalSelection AS (
    SELECT 
        rm.title_id,
        rm.movie_title,
        rm.production_year,
        ci.nr_order,
        ci.safe_role,
        mci.company_count,
        mci.company_names,
        cs.associated_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastInfoWithRoles ci ON rm.title_id = ci.movie_id
    LEFT JOIN 
        MovieCompaniesInfo mci ON rm.title_id = mci.movie_id
    LEFT JOIN 
        CorrelatedSubquery cs ON rm.title_id = cs.title_id
)
SELECT 
    fs.movie_title,
    fs.production_year,
    fs.nr_order,
    fs.safe_role,
    COALESCE(fs.company_count, 0) AS total_companies,
    COALESCE(fs.company_names, 'None') AS companies_involved,
    COALESCE(fs.associated_companies, 0) AS companies_associated,
    CASE 
        WHEN fs.company_count IS NULL THEN 'No Companies'
        WHEN fs.company_count = 0 THEN 'No Companies Found'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    FinalSelection fs
WHERE 
    fs.production_year >= 2000
ORDER BY 
    fs.production_year DESC, 
    fs.movie_title;
