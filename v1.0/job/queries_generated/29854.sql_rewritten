WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY a.id, a.title, a.production_year
),
filtered_titles AS (
    SELECT 
        *,
        CASE 
            WHEN total_cast > 10 THEN 'Featured'
            WHEN total_cast BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Minor'
        END AS cast_size_category
    FROM ranked_titles
)
SELECT 
    tt.title,
    tt.production_year,
    tt.total_cast,
    tt.keywords,
    tt.cast_size_category
FROM filtered_titles tt
WHERE tt.rank <= 5
ORDER BY tt.production_year DESC, tt.total_cast DESC;