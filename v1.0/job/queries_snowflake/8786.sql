WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(c.id) AS total_cast 
    FROM 
        aka_title t 
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id 
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id 
    GROUP BY 
        t.id, t.title, t.production_year 
), 
CompanyMovieCount AS (
    SELECT 
        mg.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count 
    FROM 
        movie_companies mc 
    JOIN 
        RankedMovies mg ON mc.movie_id = mg.movie_id 
    GROUP BY 
        mg.movie_id 
) 
SELECT 
    rm.title, 
    rm.production_year, 
    rm.total_cast, 
    cm.company_count 
FROM 
    RankedMovies rm 
JOIN 
    CompanyMovieCount cm ON rm.movie_id = cm.movie_id 
WHERE 
    rm.production_year >= 2000 
ORDER BY 
    rm.total_cast DESC, 
    cm.company_count DESC 
LIMIT 10;
