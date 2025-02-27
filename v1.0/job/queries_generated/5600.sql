WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        company_name.name AS company_name,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    JOIN 
        cast_info ON complete_cast.subject_id = cast_info.id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.title, title.production_year, company_name.name
),
KeywordCounts AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT keyword.id) AS total_keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.total_cast,
    kc.total_keywords
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCounts kc ON md.movie_id = kc.movie_id
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC, 
    kc.total_keywords DESC
LIMIT 50;
