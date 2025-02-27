WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank,
        mk.keywords
    FROM ranked_movies rm
    LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
    WHERE rm.rank <= 5
)
SELECT 
    t.title,
    COALESCE(SUM(mi.info IS NOT NULL AND it.info = 'Budget'), 0) AS total_budgets,
    tk.keywords,
    string_agg(DISTINCT n.name, ', ') AS actor_names
FROM top_movies t
LEFT JOIN movie_info mi ON t.movie_id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN aka_name n ON cc.subject_id = n.person_id
LEFT JOIN movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
WHERE 
    (cn.country_code IS NULL OR cn.country_code <> 'USA') 
    AND (t.keywords IS NOT NULL OR t.keywords LIKE '%action%')
GROUP BY t.movie_id, t.title, t.production_year, tk.keywords
ORDER BY t.production_year DESC, total_budgets DESC;
