SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS company_kind, m.production_year, k.keyword AS movie_keyword 
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN company_type c ON mc.company_type_id = c.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE a.name IS NOT NULL AND k.keyword IS NOT NULL AND mi.info_type_id = 1
ORDER BY m.production_year DESC, actor_name;
