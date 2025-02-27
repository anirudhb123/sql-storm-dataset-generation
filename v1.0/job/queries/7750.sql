SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS cast_type, 
       k.keyword AS movie_keyword, co.name AS company_name, 
       pi.info AS person_info
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN role_type rt ON ci.role_id = rt.id
JOIN comp_cast_type c ON ci.person_role_id = c.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name co ON mc.company_id = co.id
JOIN person_info pi ON a.person_id = pi.person_id
WHERE t.production_year >= 2000
  AND k.keyword IN ('Drama', 'Thriller')
  AND co.country_code = 'USA'
ORDER BY t.production_year DESC, a.name ASC;
