WITH movie_details AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        array_agg(DISTINCT keyword.keyword) AS keywords,
        COUNT(DISTINCT aka_name.name) AS alternate_names,
        COUNT(DISTINCT cast_info.person_id) AS cast_count
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        movie_keyword ON aka_title.movie_id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    LEFT JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    LEFT JOIN 
        cast_info ON complete_cast.subject_id = cast_info.person_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.title, title.production_year
),
company_details AS (
    SELECT 
        movie_companies.movie_id,
        array_agg(DISTINCT company_name.name) AS companies,
        array_agg(DISTINCT company_type.kind) AS company_types
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        company_type ON movie_companies.company_type_id = company_type.id
    GROUP BY 
        movie_companies.movie_id
)
SELECT 
    movie_details.movie_title,
    movie_details.production_year,
    movie_details.keywords,
    movie_details.alternate_names,
    movie_details.cast_count,
    company_details.companies,
    company_details.company_types
FROM 
    movie_details
LEFT JOIN 
    company_details ON movie_details.movie_title = (SELECT title FROM title WHERE id = company_details.movie_id)
ORDER BY 
    movie_details.production_year DESC, movie_details.cast_count DESC;
