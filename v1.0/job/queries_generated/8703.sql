WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    cn.name AS company_name
FROM 
    top_movies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON mc.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    cn.country_code = 'USA'
ORDER BY 
    tm.production_year DESC, tm.title;
