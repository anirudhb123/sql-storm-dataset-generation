WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
        JOIN title m ON ak.movie_id = m.id
        LEFT JOIN cast_info ca ON m.id = ca.movie_id
    GROUP BY 
        m.id
    HAVING 
        COUNT(DISTINCT ca.person_id) > 0
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
    WHERE 
        production_year > 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    GROUP_CONCAT(DISTINCT ci.note) AS cast_notes,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    top_movies tm
    LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.cast_count DESC;
