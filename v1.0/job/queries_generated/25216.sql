WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS cast_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        cast_names,
        keyword_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 10
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_names,
    tm.keyword_count,
    COALESCE(pi.info, 'No additional info') AS person_info
FROM 
    top_movies tm
LEFT JOIN 
    person_info pi ON pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    EXISTS (
        SELECT 1 
        FROM complete_cast cc 
        WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
    )
ORDER BY 
    tm.production_year DESC;
