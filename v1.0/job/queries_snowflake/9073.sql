SELECT t.title, a.name AS actor_name, c.kind AS cast_type, m.info AS movie_info, k.keyword AS movie_keyword
FROM title t
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN cast_info ci ON cc.subject_id = ci.id
JOIN aka_name a ON ci.person_id = a.person_id
JOIN movie_info m ON t.id = m.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN comp_cast_type c ON ci.role_id = c.id
WHERE t.production_year BETWEEN 2000 AND 2023
AND c.kind IN ('actor', 'actress')
ORDER BY t.production_year DESC, a.name;
