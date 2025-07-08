
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        ranked_movies 
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(frequent_actors.name, 'Unknown') AS most_frequent_actor
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    (SELECT 
        c.movie_id,
        a.name,
        COUNT(*) AS freq 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.movie_id, a.name) AS frequent_actors ON tm.movie_id = frequent_actors.movie_id
GROUP BY 
    tm.title, tm.production_year, mk.keywords, frequent_actors.name
ORDER BY 
    tm.production_year DESC, tm.title;
