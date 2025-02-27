WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
filtered_titles AS (
    SELECT 
        m.title,
        m.production_year,
        m.total_cast
    FROM 
        ranked_movies m
    WHERE 
        m.rank <= 5
),
keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    ft.title,
    ft.production_year,
    ft.total_cast,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(NULLIF(ft.production_year, 2020), 'Not 2020') AS year_status
FROM 
    filtered_titles ft
LEFT JOIN 
    keyword_counts kc ON ft.id = kc.movie_id
ORDER BY 
    ft.production_year DESC, ft.total_cast DESC
LIMIT 10;
