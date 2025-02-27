SELECT a.name AS actor_name,
       t.title AS movie_title,
       t.production_year,
       c.kind AS character_role
FROM cast_info ci
JOIN aka_name a ON ci.person_id = a.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN role_type c ON ci.role_id = c.id
ORDER BY t.production_year DESC, a.name;
