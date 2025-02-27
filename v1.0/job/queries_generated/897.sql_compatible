
WITH movie_years AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        CAST(cast_count AS FLOAT) / NULLIF(EXTRACT(YEAR FROM DATE '2024-10-01') - production_year + 1, 0) AS avg_cast_per_year
    FROM 
        movie_years
    WHERE 
        production_year IS NOT NULL
    ORDER BY 
        avg_cast_per_year DESC
    LIMIT 10
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    COALESCE(cc.cast_count, 0) AS total_cast,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    top_movies tm
LEFT JOIN 
    keyword_counts kc ON tm.movie_id = kc.movie_id
LEFT JOIN 
    movie_years cc ON tm.movie_id = cc.movie_id
WHERE 
    COALESCE(cc.cast_count, 0) > 5
ORDER BY 
    total_keywords DESC,
    total_cast DESC;
