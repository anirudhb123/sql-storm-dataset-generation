WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
), 
CastInfo AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ci.total_cast,
    ci.cast_names,
    cd.total_companies,
    cd.companies
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    (ci.total_cast IS NULL OR ci.total_cast > 5) 
    AND (rm.production_year BETWEEN 2000 AND 2023)
    AND (cd.total_companies IS NULL OR cd.total_companies > 2)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
