
WITH movie_details AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT company_name.name, ', ') AS company_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS movie_keywords
    FROM 
        title
    LEFT JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN 
        company_name ON movie_companies.company_id = company_name.id
    LEFT JOIN 
        complete_cast ON title.id = complete_cast.movie_id
    LEFT JOIN 
        aka_name ON complete_cast.subject_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        title.id, title.title, title.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        actor_names,
        company_names,
        movie_keywords,
        RANK() OVER (ORDER BY production_year DESC) AS rnk
    FROM 
        movie_details
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_names,
    company_names,
    movie_keywords
FROM 
    top_movies
WHERE 
    rnk <= 10;
