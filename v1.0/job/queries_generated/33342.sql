WITH RECURSIVE actor_hierarchy AS (
    SELECT a.id AS actor_id,
           a.name AS actor_name,
           c.movie_id,
           0 AS depth
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    WHERE a.name IS NOT NULL

    UNION ALL

    SELECT a.id,
           a.name,
           c.movie_id,
           ah.depth + 1
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN actor_hierarchy ah ON ah.movie_id = c.movie_id
    WHERE ah.depth < 3 -- Limiting depth to avoid overly deep recursion
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT ah.actor_id) AS actor_count,
    STRING_AGG(DISTINCT ah.actor_name, ', ') AS actor_names,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COALESCE(p.info, 'No info') AS person_info,
    CASE WHEN m.production_year < 2000 THEN 'Classical'
         WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
         ELSE 'Recent' END AS movie_period
FROM title m
LEFT JOIN movie_companies mc ON mc.movie_id = m.id
LEFT JOIN company_name cn ON cn.id = mc.company_id
LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN keyword k ON k.id = mk.keyword_id
LEFT JOIN person_info p ON p.person_id IN (
    SELECT person_id
    FROM aka_name a
    WHERE a.name = 'Some actor name' -- replace with an actual actor's name as a filter condition
)
LEFT JOIN actor_hierarchy ah ON ah.movie_id = m.id
WHERE m.kind_id IN (
    SELECT id FROM kind_type kt WHERE kt.kind = 'feature'
)
GROUP BY m.id, m.title, m.production_year, k.keyword, p.info
HAVING COUNT(DISTINCT ah.actor_id) > 1
ORDER BY m.production_year DESC, actor_count DESC;
