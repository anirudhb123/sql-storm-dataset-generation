
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
high_cast_movies AS (
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
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
movie_details AS (
    SELECT 
        h.title,
        h.production_year,
        h.cast_count,
        k.keywords
    FROM 
        high_cast_movies h
    LEFT JOIN 
        movie_keywords k ON h.title = (SELECT title FROM aka_title WHERE id = movie_id LIMIT 1)
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(md.keywords, 'No keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = md.title LIMIT 1) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_info_count
FROM 
    movie_details md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
