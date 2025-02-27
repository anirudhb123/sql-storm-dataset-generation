
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON movie_companies.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, title.title, title.production_year
),
filtered_keywords AS (
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
final_benchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        fk.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        filtered_keywords fk ON rm.movie_id = fk.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    cast_names,
    keywords
FROM 
    final_benchmark
WHERE 
    cast_count > 5
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 100;
