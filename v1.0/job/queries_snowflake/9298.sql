SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS company_type, COUNT(DISTINCT k.keyword) AS keyword_count, SUM(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget') THEN 1 ELSE 0 END) AS budget_info_count
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type c ON mc.company_type_id = c.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON t.id = mi.movie_id
WHERE t.production_year >= 2000 
AND c.kind LIKE 'Production%'
GROUP BY a.name, t.title, c.kind
HAVING COUNT(DISTINCT k.keyword) > 5
ORDER BY keyword_count DESC, actor_name ASC;
