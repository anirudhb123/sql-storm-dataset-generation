WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(mi.info_length) AS avg_info_length
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count, 
        avg_info_length,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, avg_info_length ASC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.avg_info_length
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
