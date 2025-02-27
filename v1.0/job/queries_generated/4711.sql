WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    GROUP BY at.id, at.title, at.production_year
),
recent_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM ranked_movies
    WHERE production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),
final_output AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(mk.keywords, 'No keywords') AS keywords
    FROM recent_movies rm
    LEFT JOIN movie_keywords mk ON rm.title = mk.movie_id
)
SELECT 
    fo.title, 
    fo.production_year, 
    fo.cast_count,
    fo.keywords,
    CASE 
        WHEN fo.cast_count > 10 THEN 'Large Cast'
        WHEN fo.cast_count > 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM final_output fo
WHERE fo.production_year IS NOT NULL
ORDER BY fo.production_year DESC, fo.cast_count DESC;

