WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        tk.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, tk.keyword
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_keyword,
    tm.cast_count,
    COUNT(DISTINCT ci.person_id) AS unique_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS company_names
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_title = (
        SELECT title FROM aka_title WHERE id = cc.movie_id
    )
LEFT JOIN 
    cast_info ci ON cc.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
GROUP BY 
    tm.movie_title, tm.production_year, tm.movie_keyword, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
