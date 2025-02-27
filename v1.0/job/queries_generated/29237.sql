WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.title, t.production_year
),
popular_titles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.cast_count
    FROM ranked_titles rt
    WHERE rt.rank <= 5
),
movie_keywords AS (
    SELECT 
        mt.movie_id,
        k.keyword
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
)
SELECT 
    pt.title,
    pt.production_year,
    pt.cast_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM popular_titles pt
LEFT JOIN movie_keywords mk ON pt.title = (
    SELECT title
    FROM title
    WHERE id IN (SELECT movie_id FROM movie_info WHERE info LIKE '%' || pt.title || '%')
    LIMIT 1
)
GROUP BY pt.title, pt.production_year, pt.cast_count
ORDER BY pt.production_year DESC, pt.cast_count DESC;
