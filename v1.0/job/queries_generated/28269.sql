WITH ranked_movies AS (
    SELECT 
        tk.title AS movie_title,
        tk.production_year,
        k.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT cn.name) AS production_companies,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY tk.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        title tk
    JOIN 
        movie_keyword mk ON tk.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON tk.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON ci.movie_id = tk.id
    GROUP BY 
        tk.id, tk.title, tk.production_year, k.keyword
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        production_companies,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.production_year,
    STRING_AGG(tm.movie_title, ', ') AS top_movies_list,
    STRING_AGG(tm.movie_keyword, ', ') AS associated_keywords,
    STRING_AGG(DISTINCT pc.name, ', ') AS popular_cast
FROM 
    top_movies tm
LEFT JOIN 
    cast_info ci ON tm.movie_title = (SELECT title FROM title WHERE id = ci.movie_id)
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    name pc ON an.id = pc.id
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
