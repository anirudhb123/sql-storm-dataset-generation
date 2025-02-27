WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS cast_count,
        AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) OVER (PARTITION BY a.id) AS avg_person_info_length
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        a.production_year IS NOT NULL
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        avg_person_info_length,
        RANK() OVER (ORDER BY cast_count DESC, avg_person_info_length DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.cast_count, 0) AS total_cast_members,
    COALESCE(tm.avg_person_info_length, 0) AS average_info_length
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
