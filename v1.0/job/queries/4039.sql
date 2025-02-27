WITH movie_ranking AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_within_year
    FROM 
        aka_title mt
    JOIN 
        complete_cast mc ON mt.id = mc.movie_id
    JOIN 
        cast_info cc ON mc.subject_id = cc.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        mt.title, mt.production_year
),
top_movies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        movie_ranking
    WHERE 
        rank_within_year <= 5
),
keyword_counts AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
final_results AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        kc.keyword_count,
        ROW_NUMBER() OVER (ORDER BY tm.production_year, tm.cast_count DESC) AS overall_rank
    FROM 
        top_movies tm
    JOIN 
        keyword_counts kc ON tm.title = (SELECT title FROM aka_title WHERE id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IS NOT NULL) LIMIT 1)
)

SELECT 
    fr.title,
    fr.production_year,
    fr.cast_count,
    COALESCE(fr.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN fr.cast_count > 10 THEN 'High Cast'
        WHEN fr.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Low Cast'
    END AS cast_category
FROM 
    final_results fr
WHERE 
    fr.keyword_count > 0 
ORDER BY 
    fr.overall_rank
LIMIT 50;
