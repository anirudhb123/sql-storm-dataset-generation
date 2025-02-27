WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank_order,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast b ON a.id = b.movie_id
    LEFT JOIN 
        cast_info c ON b.movie_id = c.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year,
        rank_order, 
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank_order = 1
),
filtered_movies AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        cn.name AS company_name
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
),
final_results AS (
    SELECT 
        fm.title, 
        fm.production_year, 
        COALESCE(MAX(mk.keyword), 'No Keywords') AS keywords
    FROM 
        filtered_movies fm
    LEFT JOIN 
        movie_keyword mk ON (SELECT movie_id FROM aka_title WHERE title = fm.title LIMIT 1) = mk.movie_id
    GROUP BY 
        fm.title, fm.production_year
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keywords
FROM 
    final_results fr
WHERE 
    fr.production_year IS NOT NULL
ORDER BY 
    fr.production_year DESC, fr.title;
