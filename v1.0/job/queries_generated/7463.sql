SELECT t.title, a.name AS actor_name, c.kind AS role_type, m.company_name, k.keyword 
FROM title t 
JOIN cast_info ci ON t.id = ci.movie_id 
JOIN aka_name a ON ci.person_id = a.person_id 
JOIN role_type c ON ci.role_id = c.id 
JOIN movie_companies mc ON t.id = mc.movie_id 
JOIN company_name m ON mc.company_id = m.id 
JOIN movie_keyword mk ON t.id = mk.movie_id 
JOIN keyword k ON mk.keyword_id = k.id 
WHERE t.production_year BETWEEN 2000 AND 2020 
  AND a.name LIKE 'J%' 
ORDER BY t.production_year DESC, a.name;
