
WITH ranked_titles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        LISTAGG(DISTINCT aka_name.name, ', ') AS cast_names,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_within_year
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
keyword_counts AS (
    SELECT 
        movie_keyword.movie_id,
        COUNT(keyword.id) AS keyword_count
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
combined_results AS (
    SELECT 
        ranked_titles.title_id,
        ranked_titles.title,
        ranked_titles.production_year,
        ranked_titles.total_cast,
        ranked_titles.cast_names,
        keyword_counts.keyword_count,
        ranked_titles.rank_within_year
    FROM 
        ranked_titles
    LEFT JOIN 
        keyword_counts ON ranked_titles.title_id = keyword_counts.movie_id
)
SELECT 
    title_id,
    title,
    production_year,
    total_cast,
    cast_names,
    COALESCE(keyword_count, 0) AS keyword_count,
    rank_within_year
FROM 
    combined_results
WHERE 
    rank_within_year = 1
ORDER BY 
    production_year DESC, 
    total_cast DESC
LIMIT 10;
