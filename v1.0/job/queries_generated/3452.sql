WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS ranking
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        ranking <= 5
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        cs.company_count, 
        cs.company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyStats cs ON tm.production_year = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_count, 0) AS company_count,
    COALESCE(md.company_names, 'No companies') AS company_names
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC;
