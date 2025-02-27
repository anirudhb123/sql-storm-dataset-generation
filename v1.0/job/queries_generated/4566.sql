WITH ranked_titles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) as year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
movie_with_keywords AS (
    SELECT 
        mt.id AS movie_id,
        string_agg(mk.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
top_movies AS (
    SELECT 
        rt.title,
        rt.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        ranked_titles rt
    LEFT JOIN 
        complete_cast cc ON rt.title = cc.subject_id
    LEFT JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    LEFT JOIN 
        movie_with_keywords mk ON rt.production_year = mk.movie_id
    WHERE 
        rt.year_rank <= 5
    GROUP BY 
        rt.title, rt.production_year, mk.keywords
)
SELECT 
    *,
    CASE 
        WHEN total_cast IS NULL THEN 0
        ELSE total_cast
    END AS total_cast_final,
    CASE 
        WHEN keywords IS NOT NULL THEN 'Contains Keywords'
        ELSE 'No Keywords Found'
    END AS keyword_status
FROM 
    top_movies
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, total_cast_final DESC;
