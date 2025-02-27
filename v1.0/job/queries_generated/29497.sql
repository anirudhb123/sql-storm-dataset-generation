WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(ci.id) AS cast_count,
        AVG(LENGTH(an.name)) AS avg_name_length
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
top_movies AS (
    SELECT 
        ranked_movies.*, 
        RANK() OVER (ORDER BY avg_name_length DESC) AS rank_by_name_length 
    FROM 
        ranked_movies
    WHERE 
        cast_count > 5
)
SELECT 
    tm.title, 
    tm.production_year, 
    kt.kind AS genre, 
    tm.cast_count, 
    tm.avg_name_length
FROM 
    top_movies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
WHERE 
    tm.rank_by_name_length <= 10
ORDER BY 
    tm.rank_by_name_length;
