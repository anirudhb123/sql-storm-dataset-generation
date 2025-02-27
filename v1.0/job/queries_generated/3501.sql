WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT ca.person_id) AS cast_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ca ON m.id = ca.movie_id
    GROUP BY 
        m.id
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
CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type 
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CombinedResults AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        cd.company_name,
        cd.company_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyDetails cd ON tm.movie_id = cd.movie_id
)
SELECT 
    movie_id, 
    title, 
    production_year, 
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type
FROM 
    CombinedResults
ORDER BY 
    production_year DESC, 
    title ASC;
