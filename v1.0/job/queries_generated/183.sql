WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
co_star_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS co_star_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(cc.co_star_count, 0) AS co_star_count
    FROM 
        ranked_movies m
    LEFT JOIN 
        co_star_counts cc ON m.movie_id = cc.movie_id
    WHERE 
        m.title_rank <= 10
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
final_movie_stats AS (
    SELECT 
        md.title,
        md.production_year,
        md.co_star_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN md.co_star_count > 5 THEN 'Ensemble Cast' 
            ELSE 'Standard Cast' 
        END AS cast_type
    FROM 
        movie_details md
    LEFT JOIN 
        keyword_counts kc ON md.movie_id = kc.movie_id
)
SELECT 
    fms.title,
    fms.production_year,
    fms.co_star_count,
    fms.keyword_count,
    fms.cast_type
FROM 
    final_movie_stats fms
WHERE 
    fms.production_year BETWEEN 2000 AND 2020
ORDER BY 
    fms.production_year DESC, 
    fms.co_star_count DESC
LIMIT 50;
