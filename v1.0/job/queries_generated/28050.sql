WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS distinct_actor_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, title.title, title.production_year
), FilteredMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, movie_title ASC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_count,
    distinct_actor_names,
    keywords
FROM 
    FilteredMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;

This SQL query benchmarks string processing by aggregating and ranking movie data based on the number of distinct actors and keywords associated with each movie produced from the year 2000 onwards. The use of Common Table Expressions (CTEs), string aggregation functions, and filtering based on the rank provides a comprehensive and interesting view of the data.
