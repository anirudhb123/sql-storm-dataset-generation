
WITH movie_stats AS (
    SELECT 
        title.title AS movie_title,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names,
        MAX(aka_title.production_year) AS release_year,
        title.id AS movie_id
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.title, title.id
),

keyword_stats AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
)

SELECT 
    ms.movie_title,
    ms.total_cast,
    ms.actor_names,
    ms.release_year,
    ks.keywords
FROM 
    movie_stats ms
LEFT JOIN 
    keyword_stats ks ON ms.movie_id = ks.movie_id
WHERE 
    ms.total_cast > 5
ORDER BY 
    ms.release_year DESC, ms.movie_title;
