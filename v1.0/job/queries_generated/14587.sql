SELECT t.title, a.name AS actor_name, pc.kind AS company_type, mi.info AS movie_info
FROM title t
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN aka_name a ON cc.subject_id = a.person_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type pc ON mc.company_type_id = pc.id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE t.production_year > 2000
ORDER BY t.title, a.name;
