WITH movie_aggregation AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.id
),
company_aggregation AS (
    SELECT 
        movie_companies.movie_id,
        STRING_AGG(DISTINCT company_name.name, ', ') AS companies,
        STRING_AGG(DISTINCT company_type.kind, ', ') AS company_types
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
    ma.movie_id,
    ma.movie_title,
    ma.production_year,
    ma.total_cast,
    ma.cast_names,
    ca.companies,
    ca.company_types,
    ma.keywords
FROM 
    movie_aggregation ma
LEFT JOIN 
    company_aggregation ca ON ma.movie_id = ca.movie_id
ORDER BY 
    ma.production_year DESC, 
    ma.total_cast DESC
LIMIT 50;
