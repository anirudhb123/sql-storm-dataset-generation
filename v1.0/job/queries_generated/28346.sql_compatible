
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
KeywordAggregation AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id, 
        rm.movie_title, 
        rm.production_year, 
        rm.cast_count, 
        rm.cast_names,
        COALESCE(ka.keywords, 'No keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordAggregation ka ON rm.movie_id = ka.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_count,
    cast_names,
    keywords
FROM 
    CompleteMovieInfo
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, 
    cast_count DESC;
