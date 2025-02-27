
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        LENGTH(a.title) AS title_length,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.title IS NOT NULL
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        title_length,
        year_rank
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 10
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_name,
    tm.title_length,
    COALESCE(kc.keyword_total, 0) AS keyword_total
FROM 
    top_movies tm
LEFT JOIN 
    keyword_count kc ON tm.movie_title = (SELECT title FROM title WHERE id = kc.movie_id)
ORDER BY 
    tm.production_year DESC, 
    tm.title_length DESC;
