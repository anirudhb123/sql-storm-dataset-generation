WITH MovieInfo AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        company.name AS company_name,
        array_agg(DISTINCT keyword.keyword) AS keywords
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name AS company ON movie_companies.company_id = company.id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        title.id, title.title, title.production_year, company.name
),
CastInfo AS (
    SELECT 
        movie_id,
        array_agg(DISTINCT aka_name.name) AS cast_names,
        COUNT(DISTINCT cast_info.person_id) AS cast_count
    FROM 
        cast_info
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        movie_id
)
SELECT 
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.company_name,
    mi.keywords,
    ci.cast_names,
    ci.cast_count
FROM 
    MovieInfo AS mi
LEFT JOIN 
    CastInfo AS ci ON mi.movie_id = ci.movie_id
WHERE 
    mi.production_year >= 2000
ORDER BY 
    mi.production_year DESC, 
    ci.cast_count DESC
LIMIT 50;
