WITH RecursiveMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_title.title AS aka_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        title.title, aka_title.title, title.production_year
),
MovieCompanies AS (
    SELECT 
        title.id AS movie_id,
        COUNT(DISTINCT company_name.name) AS total_companies,
        STRING_AGG(DISTINCT company_name.name, '; ') AS company_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        title.id
)
SELECT 
    rm.movie_title,
    rm.aka_title,
    rm.production_year,
    rm.total_cast,
    rm.cast_names,
    mc.total_companies,
    mc.company_names
FROM 
    RecursiveMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;

This query retrieves detailed information about movies released between 2000 and 2023, including their titles, any alternate titles, production years, total cast members, names of the cast, total production companies involved, and the names of those companies. It leverages Common Table Expressions (CTEs) to organize and calculate the necessary data, ensuring structured retrieval and efficient string processing for the output.
