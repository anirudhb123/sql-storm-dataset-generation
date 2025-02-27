
WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS keyword,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
), 
top_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        keyword, 
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
movies_with_info AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        tm.keyword,
        tm.cast_count,
        STRING_AGG(DISTINCT ci.note, ', ') AS cast_notes
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    GROUP BY 
        tm.movie_title, tm.production_year, tm.keyword, tm.cast_count
)
SELECT 
    mwi.movie_title, 
    mwi.production_year, 
    mwi.keyword, 
    mwi.cast_count, 
    mwi.cast_notes
FROM 
    movies_with_info mwi
WHERE 
    mwi.cast_count > 1
ORDER BY 
    mwi.production_year DESC, 
    mwi.cast_count DESC;
