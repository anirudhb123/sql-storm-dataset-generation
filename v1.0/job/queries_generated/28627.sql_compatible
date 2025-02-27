
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        production_year >= 2000
    LIMIT 10
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
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        mk.keywords
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_keywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.keywords,
    a.name AS actor_name,
    a.id AS actor_id
FROM 
    movie_details md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    md.cast_count DESC, md.title;
