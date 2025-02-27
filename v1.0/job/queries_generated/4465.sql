WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY m.id) AS total_cast
    FROM title m
    LEFT JOIN complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE m.production_year IS NOT NULL
), top_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.title_rank, 
        rm.total_cast
    FROM ranked_movies rm
    WHERE rm.title_rank <= 5
), movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    COALESCE(mk.keywords, 'No keywords') AS keywords, 
    tm.total_cast,
    CASE 
        WHEN tm.total_cast > 10 THEN 'Large Ensemble Cast'
        WHEN tm.total_cast BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_description
FROM top_movies tm
LEFT JOIN movie_keywords mk ON tm.movie_id = mk.movie_id
ORDER BY tm.production_year DESC, tm.title ASC;
