WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
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
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
FinalDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        cd.company_name,
        cd.company_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
    LEFT JOIN 
        CompanyDetails cd ON cc.movie_id = cd.movie_id
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.company_name, 'Independent') AS company_name,
    COUNT(f.company_name) AS total_companies
FROM 
    FinalDetails f
GROUP BY 
    f.title, f.production_year, f.company_name
HAVING 
    COUNT(f.company_name) > 0
ORDER BY 
    f.production_year DESC, COUNT(f.company_name) DESC;
