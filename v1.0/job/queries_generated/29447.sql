WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM title t
    JOIN cast_info c ON c.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, t.kind_id
),
filtered_titles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind_id,
        rt.cast_count
    FROM ranked_titles rt
    WHERE rt.production_year >= 2000 AND rt.cast_count >= 5
),
title_keywords AS (
    SELECT 
        mt.movie_id,
        k.keyword
    FROM movie_keyword mt
    JOIN keyword k ON k.id = mt.keyword_id
),
keyword_groups AS (
    SELECT 
        tk.movie_id,
        STRING_AGG(tk.keyword, ', ') AS keywords
    FROM title_keywords tk
    GROUP BY tk.movie_id
)
SELECT 
    ft.title,
    ft.production_year,
    kt.keywords,
    ct.kind AS company_type
FROM filtered_titles ft
LEFT JOIN movie_companies mc ON mc.movie_id = ft.title_id
LEFT JOIN company_type ct ON ct.id = mc.company_type_id 
LEFT JOIN keyword_groups kt ON kt.movie_id = ft.title_id
ORDER BY ft.production_year DESC, ft.title;
