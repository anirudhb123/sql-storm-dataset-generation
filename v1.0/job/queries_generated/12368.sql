SELECT t.id AS title_id, 
       t.title AS title, 
       t.production_year, 
       a.name AS actor_name, 
       r.role AS role_type 
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN cast_info ci ON t.id = ci.movie_id
JOIN aka_name a ON ci.person_id = a.person_id
JOIN role_type r ON ci.role_id = r.id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, t.title;
