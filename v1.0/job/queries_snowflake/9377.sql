
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
),
top_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        company_name, 
        movie_keyword
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.movie_title, 
    tm.production_year, 
    tm.company_name, 
    LISTAGG(tm.movie_keyword, ', ') WITHIN GROUP (ORDER BY tm.movie_keyword) AS keywords
FROM 
    top_movies tm
GROUP BY 
    tm.movie_title, 
    tm.production_year, 
    tm.company_name
ORDER BY 
    tm.production_year DESC, 
    tm.movie_title;
