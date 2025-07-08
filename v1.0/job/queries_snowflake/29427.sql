
WITH ranked_movies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        LISTAGG(DISTINCT aka_name.name, ', ') WITHIN GROUP (ORDER BY aka_name.name) AS cast_names,
        LISTAGG(DISTINCT keyword.keyword, ', ') WITHIN GROUP (ORDER BY keyword.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
        AND title.production_year IS NOT NULL
    GROUP BY 
        title.id, title.title, title.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        keywords
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    tm.keywords,
    COALESCE(COUNT(mc.id), 0) AS company_count,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
FROM 
    top_movies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    tm.title, tm.production_year, tm.cast_count, tm.cast_names, tm.keywords
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
