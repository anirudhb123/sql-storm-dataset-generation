WITH movie_ranking AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(cast_info.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT aka_name.name ORDER BY aka_name.name) AS cast_names,
        AVG(CASE WHEN movie_info.info_type_id = 1 THEN LENGTH(movie_info.info) ELSE NULL END) AS avg_info_length,
        COUNT(DISTINCT movie_keyword.keyword_id) AS total_keywords
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),

ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        avg_info_length,
        total_keywords,
        DENSE_RANK() OVER (ORDER BY total_cast DESC) AS rank_by_cast,
        DENSE_RANK() OVER (ORDER BY avg_info_length DESC) AS rank_by_info_length,
        DENSE_RANK() OVER (ORDER BY total_keywords DESC) AS rank_by_keywords
    FROM 
        movie_ranking
)

SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    avg_info_length,
    total_keywords,
    rank_by_cast,
    rank_by_info_length,
    rank_by_keywords,
    CASE
        WHEN rank_by_cast = 1 THEN 'Top Cast'
        WHEN rank_by_info_length = 1 THEN 'Top Info Length'
        WHEN rank_by_keywords = 1 THEN 'Top Keywords'
        ELSE 'Honorable Mention' 
    END AS status
FROM 
    ranked_movies
WHERE 
    production_year >= 2000
ORDER BY 
    rank_by_cast, title;
