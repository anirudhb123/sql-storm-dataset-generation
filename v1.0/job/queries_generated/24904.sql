WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(c.nr_order) AS avg_order
    FROM cast_info c
    WHERE c.note IS NULL
    GROUP BY c.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE LENGTH(k.keyword) > 4
    GROUP BY mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(fc.actor_count, 0) AS total_actors,
    COALESCE(kc.keyword_count, 0) AS total_keywords,
    (SELECT COUNT(*) FROM aka_title at WHERE at.movie_id = t.id AND at.kind_id IS NOT NULL) AS aka_titles_count,
    CASE 
        WHEN AVG(fc.avg_order) IS NULL THEN 'No actors'
        ELSE CASE 
            WHEN AVG(fc.avg_order) < 5 THEN 'Low average order'
            ELSE 'High average order'
        END
    END AS actor_order_status
FROM RecursiveTitleCTE t
LEFT JOIN FilteredCast fc ON t.title_id = fc.movie_id
LEFT JOIN KeywordCounts kc ON t.title_id = kc.movie_id
WHERE EXISTS (
    SELECT 1
    FROM movie_info mi
    WHERE mi.movie_id = t.title_id AND mi.info_type_id IN (
        SELECT id 
        FROM info_type 
        WHERE info LIKE '%Oscar%'
    )
) 
AND (t.production_year = (SELECT MAX(production_year) FROM title) OR t.production_year < 2000)
ORDER BY t.production_year DESC, t.title ASC
LIMIT 50;
