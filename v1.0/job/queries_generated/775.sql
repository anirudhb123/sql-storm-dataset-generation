WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
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
        rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mic.info, 'No Info Available') AS movie_info,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_info mic ON mic.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year)
    GROUP BY 
        tm.title, tm.production_year, mic.info
)
SELECT 
    md.title,
    md.production_year,
    md.movie_info,
    md.company_names,
    CASE 
        WHEN md.production_year IS NULL THEN 'Year Unknown' 
        ELSE 'Year Available' 
    END AS year_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
