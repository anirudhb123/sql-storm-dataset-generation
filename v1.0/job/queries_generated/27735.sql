WITH movie_performance AS (
    SELECT 
        movie.id AS movie_id,
        title.title,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
        COALESCE(MAX(movie_info.info), 'No Info') AS additional_info,
        AVG(CASE 
            WHEN movie_info_idx.info_type_id = 1 THEN LENGTH(movie_info_idx.info) 
            ELSE NULL 
        END) AS avg_length_info
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    LEFT JOIN 
        cast_info ON cast_info.movie_id = title.id
    LEFT JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    LEFT JOIN 
        movie_keyword ON movie_keyword.movie_id = title.id
    LEFT JOIN 
        keyword ON keyword.id = movie_keyword.keyword_id
    LEFT JOIN 
        movie_info ON movie_info.movie_id = title.id
    LEFT JOIN 
        movie_info_idx ON movie_info_idx.movie_id = title.id
    GROUP BY 
        movie.id, title.title
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        total_cast,
        cast_names,
        keywords,
        additional_info,
        avg_length_info,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS cast_rank,
        ROW_NUMBER() OVER (ORDER BY avg_length_info DESC) AS length_rank
    FROM 
        movie_performance
)

SELECT 
    movie_id,
    title,
    total_cast,
    cast_names,
    keywords,
    additional_info,
    avg_length_info,
    CASE 
        WHEN cast_rank <= 10 THEN 'Top Cast Movies'
        ELSE 'Other Movies'
    END AS category_cast,
    CASE 
        WHEN length_rank <= 10 THEN 'Top Length Info Movies'
        ELSE 'Other Movies'
    END AS category_length
FROM 
    ranked_movies
ORDER BY 
    movie_id
LIMIT 50;

