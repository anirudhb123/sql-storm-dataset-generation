WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(cc.person_id) AS cast_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast c ON mt.id = c.movie_id
    LEFT JOIN 
        cast_info cc ON c.subject_id = cc.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
movies_with_keywords AS (
    SELECT 
        mt.title,
        mt.production_year,
        mk.keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mk.keyword, 'No keyword') AS keyword,
    CASE 
        WHEN rm.rank_by_cast <= 5 THEN 'Top 5'
        WHEN rm.rank_by_cast <= 10 THEN 'Top 10'
        ELSE 'Beyond Top 10'
    END AS cast_rank_category
FROM 
    ranked_movies rm
LEFT JOIN 
    movies_with_keywords mk ON rm.title = mk.title AND rm.production_year = mk.production_year
WHERE 
    rm.cast_count > 0
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
