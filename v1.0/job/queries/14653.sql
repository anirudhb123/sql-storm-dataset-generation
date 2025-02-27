SELECT t.title,
       a.name AS actor_name,
       c.kind AS cast_type,
       m.info AS movie_info
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN aka_name a ON mc.movie_id = a.person_id
JOIN cast_info ci ON t.id = ci.movie_id
JOIN role_type rt ON ci.role_id = rt.id
JOIN complete_cast cc ON cc.movie_id = t.id
JOIN movie_info m ON t.id = m.movie_id
JOIN comp_cast_type c ON ci.person_role_id = c.id
WHERE t.production_year >= 2000
ORDER BY t.title;
