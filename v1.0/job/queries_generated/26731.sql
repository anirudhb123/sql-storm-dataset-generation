WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS actor_name,
        title.production_year,
        count(DISTINCT cast_info.person_id) AS actor_count,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT company_name.name, ', ') AS company_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
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
        title.id, aka_name.name, title.production_year
),
AggregatedData AS (
    SELECT
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        MAX(actor_count) AS max_actors,
        COUNT(DISTINCT keywords) AS total_keywords,
        STRING_AGG(DISTINCT company_names, '; ') AS unique_companies
    FROM
        MovieDetails
    GROUP BY
        movie_title, production_year
)
SELECT 
    production_year,
    COUNT(movie_title) AS movie_count,
    AVG(max_actors) AS avg_actors_per_movie,
    SUM(total_keywords) AS total_keywords_collected,
    STRING_AGG(DISTINCT actors, '; ') AS all_actors_per_year,
    STRING_AGG(DISTINCT unique_companies, '; ') AS all_companies_per_year
FROM 
    AggregatedData
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
