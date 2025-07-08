
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
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
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS companies_count,
        LISTAGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title AS Top_Movie_Title,
    tm.production_year AS Year,
    cs.companies_count AS Company_Count,
    cs.company_names AS Company_Names,
    COALESCE(mi.info, 'No Additional Info') AS More_Info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyStats cs ON tm.movie_id = cs.movie_id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis' LIMIT 1)
WHERE 
    (tm.production_year > 2000 AND cs.companies_count > 1) OR cs.companies_count IS NULL
ORDER BY 
    tm.production_year DESC, cs.companies_count DESC;
