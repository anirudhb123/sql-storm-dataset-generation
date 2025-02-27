WITH MovieDetails AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        array_agg(DISTINCT name.name) AS cast_names,
        array_agg(DISTINCT keyword.keyword) AS keywords,
        array_agg(DISTINCT company_name.name) AS production_companies
    FROM 
        title
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
        aka_name AS name ON cast_info.person_id = name.person_id
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        title.id
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_names,
        keywords,
        production_companies,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS ranked_title
    FROM 
        MovieDetails
)
SELECT 
    ranked_title,
    movie_title,
    production_year,
    cast_names,
    keywords,
    production_companies
FROM 
    RankedMovies
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, ranked_title;

