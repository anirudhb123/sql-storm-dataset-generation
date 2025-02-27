WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS all_keywords
    FROM
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        all_actors, 
        all_keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.all_actors,
    tm.all_keywords
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;