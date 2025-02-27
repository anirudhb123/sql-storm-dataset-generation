SELECT a.name AS actor_name, 
       t.title AS movie_title, 
       c.kind AS company_type, 
       COUNT(DISTINCT mc.id) AS company_count, 
       AVG(m.production_year) AS avg_production_year
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type c ON mc.company_type_id = c.id
JOIN title m ON t.id = m.id
WHERE c.kind IS NOT NULL
GROUP BY a.name, t.title, c.kind
HAVING COUNT(DISTINCT mc.id) > 1
ORDER BY avg_production_year DESC, actor_name ASC;
