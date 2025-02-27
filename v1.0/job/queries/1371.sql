WITH RankedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
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
FilteredCompanies AS (
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
    WHERE 
        ct.kind IN ('Production', 'Distribution')
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        string_agg(DISTINCT c.name, ', ') AS actors,
        string_agg(DISTINCT f.company_name, ', ') AS companies,
        MAX(f.company_type) AS company_type
    FROM 
        TopMovies m
    LEFT JOIN 
        cast_info ci ON m.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        FilteredCompanies f ON m.title = (SELECT title FROM aka_title WHERE id = f.movie_id)
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    title, 
    production_year,
    actors,
    companies,
    COALESCE(company_type, 'N/A') AS company_type
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    title;
