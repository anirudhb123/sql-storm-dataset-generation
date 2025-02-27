WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(cast_info.id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
keyword_movies AS (
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
detailed_movies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        COALESCE(km.keywords, 'No Keywords') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_movies km ON rm.movie_id = km.movie_id
),
final_result AS (
    SELECT
        dm.movie_id,
        dm.movie_title,
        dm.production_year,
        dm.cast_count,
        dm.cast_names,
        dm.keywords,
        CASE 
            WHEN dm.cast_count > 5 THEN 'Large Cast'
            WHEN dm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size_category
    FROM 
        detailed_movies dm
    WHERE 
        dm.production_year >= 2000
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    cast_names,
    keywords,
    cast_size_category
FROM 
    final_result
ORDER BY 
    production_year DESC, 
    cast_count DESC;
