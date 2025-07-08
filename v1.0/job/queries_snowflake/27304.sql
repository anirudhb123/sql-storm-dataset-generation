
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS year_rank
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
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND a.production_year >= 2000
),
filtered_movies AS (
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
    f.movie_title,
    f.production_year,
    f.company_name,
    LISTAGG(f.movie_keyword, ', ') WITHIN GROUP (ORDER BY f.movie_keyword) AS keywords
FROM 
    filtered_movies f
GROUP BY 
    f.movie_title, f.production_year, f.company_name
ORDER BY 
    f.production_year DESC, f.movie_title;
