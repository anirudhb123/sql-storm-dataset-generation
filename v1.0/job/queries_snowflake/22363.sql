
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT rt.role, ', ') AS roles_list
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cr.total_cast,
        cr.roles_list,
        ROW_NUMBER() OVER (ORDER BY cr.total_cast DESC) AS cast_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.movie_id = cr.movie_id
    WHERE 
        cr.total_cast > 3
    OR 
        (cr.total_cast IS NULL AND rm.production_year > 2000)  
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') AS companies,
        COUNT(DISTINCT cn.country_code) AS distinct_countries
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(cd.companies, 'No companies') AS companies,
    COALESCE(cd.distinct_countries, 0) AS distinct_countries,
    CASE 
        WHEN ca.total_cast IS NULL THEN 'Unknown'
        WHEN ca.total_cast > 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN cd.distinct_countries IS NULL THEN 'No Info'
        WHEN cd.distinct_countries > 1 THEN 'International'
        ELSE 'Domestic'
    END AS company_geography
FROM 
    TopMovies tm
LEFT JOIN 
    CastRoles ca ON tm.movie_id = ca.movie_id
LEFT JOIN 
    CompanyData cd ON tm.movie_id = cd.movie_id
WHERE 
    tm.cast_rank <= 10  
ORDER BY 
    tm.production_year DESC, 
    tm.title;
