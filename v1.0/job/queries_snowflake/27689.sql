
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT * 
    FROM ranked_movies 
    WHERE rank <= 10
),
cast_summary AS (
    SELECT 
        c.movie_id,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        top_movies tm ON c.movie_id = tm.movie_id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.keywords,
    cs.cast_names,
    cs.cast_count
FROM 
    top_movies tm
LEFT JOIN 
    cast_summary cs ON tm.movie_id = cs.movie_id
ORDER BY 
    tm.production_year DESC, tm.movie_id;
