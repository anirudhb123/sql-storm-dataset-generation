WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
selected_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(sk.keywords, 'No keywords') AS keywords,
    tm.cast_count
FROM 
    top_movies tm
LEFT JOIN 
    selected_keywords sk ON tm.title = (SELECT title FROM aka_title WHERE id = (SELECT movie_id FROM movie_info WHERE movie_id = tm.id LIMIT 1))
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
