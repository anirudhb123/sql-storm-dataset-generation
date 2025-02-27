WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, ml.linked_movie_id, 1 AS level
    FROM title m
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    WHERE m.production_year > 2000
  
    UNION ALL
  
    SELECT m.id, m.title, m.production_year, ml.linked_movie_id, mh.level + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(aka.name, 'Unknown') AS actor_name,
    COUNT(mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mi.info::FLOAT) AS avg_info_length
FROM title t
LEFT JOIN cast_info ci ON t.id = ci.movie_id
LEFT JOIN aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (
    SELECT id FROM info_type WHERE info = 'Summary'
)
WHERE t.production_year >= 2000
GROUP BY t.title, t.production_year, aka.name
HAVING COUNT(mc.company_id) > 2
ORDER BY t.production_year DESC, COUNT(mc.company_id) DESC;
