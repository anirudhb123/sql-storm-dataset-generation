WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
popular_movies AS (
    SELECT 
        r.movie_id,
        r.title,
        COUNT(ci.id) AS cast_count
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    GROUP BY 
        r.movie_id, r.title
    HAVING 
        COUNT(ci.id) > 5 
),
null_handling AS (
    SELECT 
        pm.title,
        pm.cast_count,
        COALESCE(NULLIF(pm.title, ''), 'Untitled') AS safe_title,
        NULLIF(pm.cast_count, 0) AS safe_cast_count
    FROM 
        popular_movies pm
),
final_selection AS (
    SELECT 
        nh.safe_title,
        nh.safe_cast_count,
        ROW_NUMBER() OVER (ORDER BY nh.safe_cast_count DESC) AS selection_rank
    FROM 
        null_handling nh
    WHERE 
        nh.safe_cast_count IS NOT NULL
)
SELECT 
    fs.safe_title,
    fs.safe_cast_count,
    (SELECT AVG(safe_cast_count) FROM final_selection) AS avg_cast_count
FROM 
    final_selection fs
WHERE 
    fs.selection_rank <= 10 
ORDER BY 
    fs.safe_cast_count DESC;