SELECT a.name AS actor_name, m.title AS movie_title, c.kind AS comp_cast_type
FROM cast_info ci
JOIN aka_name a ON ci.person_id = a.person_id
JOIN title m ON ci.movie_id = m.id
JOIN movie_companies mc ON m.id = mc.movie_id
JOIN comp_cast_type c ON ci.person_role_id = c.id
WHERE m.production_year >= 2000
ORDER BY m.title;
