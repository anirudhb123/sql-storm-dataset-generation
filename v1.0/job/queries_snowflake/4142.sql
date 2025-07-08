
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
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
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
    HAVING 
        COUNT(DISTINCT mc.company_id) > 5
),
MovieRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cr.role, 'No Role') AS role,
    tm.company_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieRoles cr ON tm.movie_id = cr.movie_id
WHERE 
    (tm.production_year = 2000 OR tm.production_year = 2020)
ORDER BY 
    tm.production_year DESC, 
    tm.title ASC;
