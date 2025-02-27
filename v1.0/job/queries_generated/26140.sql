WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        title.kind_id,
        ARRAY_AGG(DISTINCT aka_name.name) AS aka_names,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT keyword.keyword) AS keywords
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        title.id
),
MovieCompanies AS (
    SELECT 
        movie_id,
        ARRAY_AGG(DISTINCT company_name.name) AS production_companies
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_id
),
FinalOutput AS (
    SELECT 
        MD.movie_title,
        MD.production_year,
        MD.cast_count,
        COALESCE(MC.production_companies, '{}') AS production_companies,
        MD.keywords
    FROM 
        MovieDetails MD
    LEFT JOIN 
        MovieCompanies MC ON MD.movie_title = MC.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    production_companies,
    keywords
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, 
    cast_count DESC;
