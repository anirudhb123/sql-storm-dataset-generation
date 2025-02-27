WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),

top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        ranked_movies
    WHERE 
        rank <= 5  
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    ARRAY_AGG(DISTINCT ci.note) AS cast_notes
FROM 
    top_movies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.production_year, tm.cast_count DESC;