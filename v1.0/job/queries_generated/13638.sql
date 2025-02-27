SELECT t.title, p.id AS person_id, p.name AS actor_name, c.kind AS role_type
FROM title t
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.id
JOIN aka_name p ON ci.person_id = p.person_id
JOIN role_type c ON ci.role_id = c.id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, t.title, actor_name;
