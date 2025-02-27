
WITH movie_details AS (
    SELECT 
        title.id AS movie_id,
        title.title AS title,
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
keyword_details AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
info_details AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT movie_info.info, '; ') AS info
    FROM 
        movie_info
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.cast_names,
    COALESCE(kd.keywords, 'No keywords') AS keywords,
    COALESCE(id.info, 'No additional info') AS additional_info
FROM 
    movie_details md
LEFT JOIN 
    keyword_details kd ON md.movie_id = kd.movie_id
LEFT JOIN 
    info_details id ON md.movie_id = id.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 50;
