EXPLAIN ANALYZE
SELECT t.title, a.name AS actor_name, c.kind AS role_type, m.name AS company_name, 
       m.year AS production_year, COUNT(DISTINCT k.keyword) AS keyword_count
FROM title t
JOIN cast_info ci ON t.id = ci.movie_id
JOIN aka_name a ON ci.person_id = a.person_id
JOIN role_type c ON ci.role_id = c.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name m ON mc.company_id = m.id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE t.production_year >= 2000 
  AND c.kind IS NOT NULL 
  AND m.country_code IN ('USA', 'UK', 'CA')  
GROUP BY t.id, a.name, c.kind, m.name, m.production_year
ORDER BY keyword_count DESC, t.title ASC
LIMIT 100;
