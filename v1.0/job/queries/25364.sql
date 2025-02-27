
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_stats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        COALESCE(ks.keyword_count, 0) AS keyword_count,
        ks.keywords
    FROM 
        ranked_movies rm
    LEFT JOIN 
        keyword_stats ks ON rm.movie_id = ks.movie_id
),
final_report AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        md.cast_names,
        md.keyword_count,
        md.keywords,
        CASE
            WHEN md.keyword_count = 0 THEN 'No Keywords'
            WHEN md.keyword_count < 5 THEN 'Few Keywords'
            ELSE 'Rich Keywords'
        END AS keyword_quality
    FROM 
        movie_details md
)
SELECT 
    title,
    production_year,
    cast_count,
    cast_names,
    keyword_count,
    keywords,
    keyword_quality
FROM 
    final_report
WHERE 
    production_year >= 2000
ORDER BY 
    cast_count DESC, production_year DESC;
