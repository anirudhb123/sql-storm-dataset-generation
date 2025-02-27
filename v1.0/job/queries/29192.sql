WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year
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
final_benchmark AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        kc.keyword_count,
        rm.aliases
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_counts kc ON rm.movie_id = kc.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.cast_count,
    COALESCE(fb.keyword_count, 0) AS keyword_count,
    fb.aliases
FROM 
    final_benchmark fb
ORDER BY 
    fb.production_year DESC, 
    fb.cast_count DESC;
