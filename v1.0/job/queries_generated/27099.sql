WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT aka_name.name) AS actors,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
),
movie_ranking AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actors,
        keywords,
        DENSE_RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.cast_count,
    r.actors,
    r.keywords,
    r.rank
FROM 
    movie_ranking r
WHERE 
    r.rank <= 10
ORDER BY 
    r.rank;
