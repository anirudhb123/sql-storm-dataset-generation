WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),

most_popular_movies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count,
        r.keyword_count,
        ROW_NUMBER() OVER (ORDER BY r.cast_count DESC) AS row_num
    FROM 
        ranked_movies r
    WHERE 
        r.rank_by_cast <= 5
),

null_keyword_movies AS (
    SELECT 
        m.title,
        m.production_year,
        m.cast_count
    FROM 
        most_popular_movies m
    WHERE 
        m.keyword_count IS NULL
)

SELECT 
    COALESCE(mp.production_year, nk.production_year) AS production_year,
    COALESCE(mp.title, nk.title) AS title,
    COALESCE(mp.cast_count, nk.cast_count) AS cast_count,
    CASE 
        WHEN mp.title IS NOT NULL AND nk.title IS NOT NULL THEN 'Both'
        WHEN mp.title IS NOT NULL THEN 'Popular'
        WHEN nk.title IS NOT NULL THEN 'No Keywords'
        ELSE 'Unknown'
    END AS movie_status
FROM 
    most_popular_movies mp
FULL OUTER JOIN 
    null_keyword_movies nk ON mp.production_year = nk.production_year
ORDER BY 
    production_year DESC, cast_count DESC;
