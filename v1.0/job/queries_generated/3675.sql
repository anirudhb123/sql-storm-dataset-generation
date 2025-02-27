WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY r.role_id) AS rn,
        COALESCE(m.id, 0) AS movie_id
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword k ON a.id = k.movie_id
    LEFT JOIN 
        movie_info i ON a.id = i.movie_id
    LEFT JOIN 
        cast_info r ON a.id = r.movie_id
    LEFT JOIN 
        movie_companies c ON a.id = c.movie_id
), MovieCounts AS (
    SELECT 
        production_year, 
        COUNT(*) AS movie_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
    GROUP BY 
        production_year
), CompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_kind
    FROM 
        movie_companies m
    INNER JOIN 
        company_name c ON m.company_id = c.id
    INNER JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        ct.kind IN ('Producer', 'Distributor')
), FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        mc.movie_count,
        cd.company_name
    FROM 
        RankedMovies rm
    JOIN 
        MovieCounts mc ON rm.production_year = mc.production_year
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(title, '; ') AS titles,
    SUM(CASE WHEN company_name IS NULL THEN 1 ELSE 0 END) AS unproduced_movies
FROM 
    FinalResults
GROUP BY 
    production_year
ORDER BY 
    production_year DESC
LIMIT 10;
