SELECT p.name AS actor_name, 
       t.title AS movie_title, 
       c.kind AS company_type, 
       mi.info AS movie_info, 
       k.keyword AS movie_keyword
FROM person_info pi
JOIN aka_name p ON pi.person_id = p.person_id
JOIN cast_info ci ON p.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN company_type c ON mc.company_type_id = c.id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
WHERE c.kind LIKE 'Production%' 
  AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%box office%')
  AND t.production_year BETWEEN 2000 AND 2023
ORDER BY t.production_year DESC, p.name ASC;
