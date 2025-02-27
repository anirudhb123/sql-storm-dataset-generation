WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
), 
CompanyStatistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
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
    ts.total_cast,
    cs.total_companies,
    COALESCE(cs.company_names, 'No companies') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    RankedMovies ts ON tm.title = ts.title AND tm.production_year = ts.production_year
LEFT JOIN 
    CompanyStatistics cs ON ts.movie_id = cs.movie_id
WHERE 
    (ts.total_cast IS NOT NULL OR cs.total_companies IS NOT NULL)
ORDER BY 
    tm.production_year DESC, ts.total_cast DESC;
