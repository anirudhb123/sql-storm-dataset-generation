SELECT a.name AS actor_name, 
       t.title AS movie_title, 
       c.kind AS cast_type, 
       m.info AS movie_info, 
       k.keyword AS movie_keyword 
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN movie_info m ON t.id = m.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN role_type r ON ci.role_id = r.id
JOIN kind_type kt ON t.kind_id = kt.id
WHERE t.production_year >= 2000 
  AND k.keyword LIKE 'Action%'
  AND r.role IS NOT NULL
ORDER BY t.production_year DESC, a.name;
