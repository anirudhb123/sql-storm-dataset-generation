SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS role
FROM cast_info ci
JOIN aka_name a ON ci.person_id = a.person_id
JOIN title t ON ci.movie_id = t.id
JOIN role_type c ON ci.role_id = c.id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, a.name;
