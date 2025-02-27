WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title m ON mc.movie_id = m.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    ci.company_name,
    ci.company_type,
    COALESCE(ci.movie_count, 0) AS movie_count,
    CASE 
        WHEN ci.movie_count IS NULL THEN 'No Companies'
        ELSE 'Has Companies'
    END AS company_status
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.production_year = ci.movie_count
ORDER BY 
    tm.production_year DESC, tm.title;
