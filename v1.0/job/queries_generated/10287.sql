SELECT t.title, a.name as actor_name, c.kind as role
FROM title t
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN aka_name a ON cc.subject_id = a.person_id
JOIN cast_info ci ON a.person_id = ci.person_id AND ci.movie_id = t.id
JOIN comp_cast_type c ON ci.person_role_id = c.id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, a.name;
