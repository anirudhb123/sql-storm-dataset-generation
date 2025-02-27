SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS company_type, m.production_year
FROM cast_info ci
JOIN aka_name a ON ci.person_id = a.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type c ON mc.company_type_id = c.id
JOIN title m ON t.id = m.id
WHERE m.production_year > 2000
ORDER BY m.production_year DESC;
