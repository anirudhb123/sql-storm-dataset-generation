WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year BETWEEN 1990 AND 2000
    UNION ALL
    SELECT m.id AS movie_id, m.title, m.production_year, mh.level + 1
    FROM aka_title m
    JOIN movie_link ml ON m.id = ml.linked_movie_id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5
),
top_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM movie_hierarchy m
    LEFT JOIN cast_info c ON m.movie_id = c.movie_id
    GROUP BY m.movie_id, m.title, m.production_year
    HAVING COUNT(DISTINCT c.person_id) > 2
),
related_keywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(rk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN tm.cast_count > 10 THEN 'Ensemble Cast'
        WHEN tm.cast_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    CASE 
        WHEN EXTRACT(YEAR FROM cast('2024-10-01' as date)) - tm.production_year <= 3 THEN 'Recent Release'
        ELSE 'Classic'
    END AS age_category
FROM top_movies tm
LEFT JOIN related_keywords rk ON tm.movie_id = rk.movie_id
WHERE tm.rn <= 5
ORDER BY tm.production_year DESC, tm.cast_count DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;