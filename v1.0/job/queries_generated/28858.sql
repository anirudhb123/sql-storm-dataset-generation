WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(STRING_AGG(k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL), 'No Keywords') AS keywords,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        COALESCE(SUM(mi.info IS NOT NULL)::int, 0) AS info_count
    FROM title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON m.id = ci.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY m.id, m.title
),
completed_ranks AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.keywords,
        rm.cast_count,
        rm.info_count,
        RANK() OVER (ORDER BY rm.cast_count DESC, rm.info_count DESC) AS rank
    FROM ranked_movies rm
)
SELECT 
    cr.rank,
    cr.title,
    cr.keywords,
    cr.cast_count,
    cr.info_count
FROM completed_ranks cr
WHERE cr.cast_count > 0
ORDER BY cr.rank
LIMIT 20;
