WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        comp.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name comp ON mc.company_id = comp.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON t.id = c.movie_id
    WHERE t.production_year >= 2000
    GROUP BY t.id, t.title, t.production_year, comp.name
),
ranked_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_name,
        md.keywords,
        md.cast_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_by_cast
    FROM movie_details md
)
SELECT 
    r.movie_title,
    r.production_year,
    r.company_name,
    r.keywords,
    r.cast_count,
    CASE 
        WHEN r.rank_by_cast <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM ranked_movies r
WHERE r.rank_by_cast IS NOT NULL
ORDER BY r.production_year DESC, r.rank_by_cast;
