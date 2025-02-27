WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.movie_id,
        t.title,
        m.company_id,
        0 AS level
    FROM movie_companies m
    JOIN aka_title t ON m.movie_id = t.id
    WHERE m.note IS NOT NULL

    UNION ALL

    SELECT 
        ch.movie_id,
        t.title,
        ch.company_id,
        level + 1
    FROM movie_companies ch
    JOIN movie_hierarchy mh ON ch.movie_id = mh.movie_id
    JOIN aka_title t ON ch.movie_id = t.id
)
SELECT 
    t.title,
    ARRAY_AGG(DISTINCT c.name) AS cast_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(mh.level) AS company_levels,
    COALESCE(SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_info
FROM 
    aka_title t
LEFT JOIN cast_info ci ON t.id = ci.movie_id
LEFT JOIN aka_name c ON ci.person_id = c.person_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN movie_hierarchy mh ON t.id = mh.movie_id
LEFT JOIN person_info pi ON ci.person_id = pi.person_id
WHERE 
    t.production_year >= 2000
    AND (ci.note IS NULL OR ci.note <> 'Cameo')
GROUP BY 
    t.id, t.title
ORDER BY 
    keyword_count DESC,
    t.title ASC
LIMIT 100;
