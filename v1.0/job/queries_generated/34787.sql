WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        0 AS level
    FROM aka_name a
    WHERE a.name IS NOT NULL

    UNION ALL

    SELECT 
        a.id,
        a.name,
        ah.level + 1 AS level
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN actor_hierarchy ah ON c.movie_id = (SELECT m.id FROM title m WHERE m.production_year = 2022 LIMIT 1)
)

SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    SUM(m.production_year) AS total_production_years,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT c.kind_id) > 1 THEN 'Diverse Roles'
        ELSE 'Single Role'
    END AS role_diversity,
    COUNT(DISTINCT i.info) FILTER (WHERE i.info IS NOT NULL) AS non_null_info_count
FROM actor_hierarchy a
JOIN cast_info ci ON a.actor_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info i ON t.movie_id = i.movie_id
LEFT JOIN company_name c ON c.id = (
    SELECT mc.company_id 
    FROM movie_companies mc 
    WHERE mc.movie_id = t.id
    ORDER BY mc.note DESC
    LIMIT 1
)
WHERE t.production_year >= 2000
AND t.kind_id NOT IN (SELECT id FROM kind_type WHERE kind = 'Short')
GROUP BY t.title, a.name
ORDER BY movie_count DESC, total_production_years DESC
LIMIT 10;

