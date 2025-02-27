WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    m.cast_count,
    COALESCE(n.name, 'Unknown') AS top_actor
FROM 
    top_movies m
LEFT JOIN 
    movie_keywords k ON m.title = (SELECT title FROM aka_title WHERE id = m.id)
LEFT JOIN 
    cast_info c ON m.title = (SELECT t.title FROM aka_title t WHERE t.id = c.movie_id)
LEFT JOIN 
    aka_name n ON c.person_id = n.person_id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, 
    m.cast_count DESC;
