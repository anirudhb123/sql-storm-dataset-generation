
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(cast_info.id) AS cast_count,
        ARRAY_AGG(DISTINCT aka_name.name) AS cast_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, title.title, title.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
)

SELECT 
    RM.movie_title,
    RM.production_year,
    RM.cast_count,
    RM.cast_names,
    STRING_AGG(DISTINCT keyword.keyword, ', ') AS associated_keywords
FROM 
    RankedMovies RM
LEFT JOIN 
    movie_keyword ON RM.movie_id = movie_keyword.movie_id
LEFT JOIN 
    keyword ON movie_keyword.keyword_id = keyword.id
GROUP BY 
    RM.movie_title, RM.production_year, RM.cast_count, RM.cast_names
ORDER BY 
    RM.cast_count DESC;
