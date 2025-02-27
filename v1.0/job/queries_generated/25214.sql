WITH detailed_movie_info AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS actor_name,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keyword_list,
        title.production_year,
        COUNT(DISTINCT movie_companies.company_id) AS production_companies_count
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, aka_name.id
),
aggregated_movie_data AS (
    SELECT 
        movie_title,
        actor_name,
        STRING_AGG(DISTINCT keyword_list, '; ') AS all_keywords,
        AVG(production_year) AS avg_production_year,
        SUM(production_companies_count) AS total_production_companies
    FROM 
        detailed_movie_info
    GROUP BY 
        movie_title, actor_name
)
SELECT 
    actor_name,
    movie_title,
    all_keywords,
    avg_production_year,
    total_production_companies
FROM 
    aggregated_movie_data
WHERE 
    total_production_companies > 5
ORDER BY 
    avg_production_year DESC, actor_name;
