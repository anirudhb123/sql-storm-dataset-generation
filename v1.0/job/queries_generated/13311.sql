SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS role_type
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN role_type c ON ci.role_id = c.id
WHERE a.name IS NOT NULL
ORDER BY a.name, t.production_year;
