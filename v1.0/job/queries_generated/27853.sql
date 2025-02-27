WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        *,
        CASE 
            WHEN cast_count > 10 THEN 'Blockbuster'
            WHEN cast_count BETWEEN 5 AND 10 THEN 'Moderately Popular'
            ELSE 'Indie'
        END AS movie_type
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.keywords,
    tm.movie_type
FROM 
    top_movies tm
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
