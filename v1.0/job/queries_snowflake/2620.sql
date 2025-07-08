WITH movie_keywords AS (
    SELECT m.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN aka_title m ON mk.movie_id = m.movie_id
    GROUP BY m.movie_id
),
company_counts AS (
    SELECT mc.movie_id, COUNT(DISTINCT c.id) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    WHERE c.country_code IS NOT NULL
    GROUP BY mc.movie_id
),
top_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        COALESCE(cc.company_count, 0) AS company_count
    FROM aka_title a
    LEFT JOIN movie_keywords mk ON a.movie_id = mk.movie_id
    LEFT JOIN company_counts cc ON a.movie_id = cc.movie_id
    WHERE a.production_year BETWEEN 2000 AND 2023
    ORDER BY a.production_year DESC
    LIMIT 10
)
SELECT 
    t.title,
    t.production_year,
    t.keyword_count,
    t.company_count,
    CASE 
        WHEN t.keyword_count > 5 THEN 'High'
        WHEN t.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_ranking,
    CASE 
        WHEN t.company_count > 3 THEN 'Produced with multiple companies'
        ELSE 'Single or fewer companies'
    END AS company_analysis
FROM top_movies t
ORDER BY t.keyword_count DESC, t.company_count DESC;
