
WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
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
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    ak.name AS actor_name,
    COUNT(DISTINCT ci.person_id) AS distinct_cast_count
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = (SELECT id FROM title WHERE title = tm.title LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM title WHERE title = tm.title LIMIT 1)
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
GROUP BY 
    tm.title, tm.production_year, mk.keywords, ak.name
HAVING 
    COUNT(DISTINCT ak.id) > 1
ORDER BY 
    tm.production_year DESC, 
    distinct_cast_count DESC;
