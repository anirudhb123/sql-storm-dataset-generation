SELECT t.title, a.name AS actor_name, ci.role_id, ct.kind AS cast_type
FROM title t
JOIN movie_companies mc ON mc.movie_id = t.id
JOIN company_name cn ON cn.id = mc.company_id
JOIN complete_cast cc ON cc.movie_id = t.id
JOIN cast_info ci ON ci.movie_id = cc.movie_id
JOIN aka_name a ON a.person_id = ci.person_id
JOIN comp_cast_type ct ON ct.id = ci.person_role_id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, a.name;
