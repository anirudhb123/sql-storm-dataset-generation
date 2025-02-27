WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_by_title,
        COUNT(c.id) OVER (PARTITION BY a.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
complex_info AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(CAST(m.cast_count AS TEXT), 'No cast') AS cast_count_text,
        (SELECT COUNT(DISTINCT k.keyword) 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = m.movie_id) AS keyword_count
    FROM 
        ranked_movies m
    WHERE 
        m.rank_by_title <= 5
),
final_results AS (
    SELECT 
        ci.movie_id,
        ci.title,
        ci.production_year,
        ci.cast_count_text,
        ci.keyword_count
    FROM 
        complex_info ci
    WHERE 
        ci.keyword_count > 2
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count_text,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic' 
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
        ELSE 'Recent'
    END AS era
FROM 
    final_results f
ORDER BY 
    f.production_year DESC, f.title;
