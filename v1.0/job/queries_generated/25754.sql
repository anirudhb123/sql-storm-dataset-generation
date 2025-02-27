WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actor_names,
        RANK() OVER (ORDER BY COUNT(cast_info.person_id) DESC) AS rank
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
keyword_stats AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    ks.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_stats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
