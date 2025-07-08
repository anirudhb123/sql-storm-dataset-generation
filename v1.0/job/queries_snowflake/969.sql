
WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 10
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
movie_info_with_keywords AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        mk.keywords
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id
    LEFT JOIN 
        movie_keywords mk ON mi.movie_id = mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(m.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN m.cast_count > 10 THEN 'Large Cast'
        WHEN m.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    movie_info_with_keywords m
WHERE 
    m.production_year BETWEEN 2000 AND 2020
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
