SELECT a.name AS actor_name,
       t.title AS movie_title,
       c.kind AS company_type,
       COUNT(mi.id) AS info_count
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type c ON mc.company_type_id = c.id
LEFT JOIN movie_info mi ON t.id = mi.movie_id
WHERE t.production_year > 2000
  AND c.kind = 'Distributor'
GROUP BY a.name, t.title, c.kind
ORDER BY info_count DESC, a.name ASC
LIMIT 100;