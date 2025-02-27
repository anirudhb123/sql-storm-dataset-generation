WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        aka_title.kind_id,
        COUNT(cast_info.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.id) DESC) AS rank
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year, aka_title.kind_id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        TopMovies.movie_id,
        TopMovies.title,
        TopMovies.production_year,
        TopMovies.cast_count,
        string_agg(DISTINCT aka_name.name, ', ') AS cast_names,
        string_agg(DISTINCT company_name.name, ', ') AS companies_involved
    FROM 
        TopMovies
    LEFT JOIN 
        cast_info ON TopMovies.movie_id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_companies ON TopMovies.movie_id = movie_companies.movie_id
    LEFT JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        TopMovies.movie_id, TopMovies.title, TopMovies.production_year, TopMovies.cast_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    md.companies_involved
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
