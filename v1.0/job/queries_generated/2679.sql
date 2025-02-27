WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT c.name || ' (' || ct.kind || ')') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(ci.companies, 'No companies associated') AS companies,
    tm.total_cast
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyInfo ci ON tm.title = ci.movie_id
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
