WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY mc.movie_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ci.company_name,
        ci.company_type,
        ci.num_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.year_rank <= 3
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.company_name, 'Independent') AS production_company,
    tm.num_companies,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = tm.movie_id) AS keyword_count
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title;
