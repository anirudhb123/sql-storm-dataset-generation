WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
        AND title.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        title.id, title.title, title.production_year
),
popular_genres AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
final_output AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        pg.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        popular_genres pg ON rm.movie_id = pg.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_count,
    cast_names,
    COALESCE(keywords, 'No keywords available') AS keywords
FROM 
    final_output
ORDER BY 
    cast_count DESC, production_year DESC
LIMIT 10;