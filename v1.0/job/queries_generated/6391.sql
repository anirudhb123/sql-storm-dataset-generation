SELECT p.name AS actor_name, 
       t.title AS movie_title, 
       k.keyword AS movie_keyword, 
       c.kind AS company_type, 
       i.info AS movie_info 
FROM aka_name p 
JOIN cast_info ci ON p.person_id = ci.person_id 
JOIN aka_title t ON ci.movie_id = t.id 
JOIN movie_keyword mk ON t.id = mk.movie_id 
JOIN keyword k ON mk.keyword_id = k.id 
JOIN movie_companies mc ON t.id = mc.movie_id 
JOIN company_type c ON mc.company_type_id = c.id 
JOIN movie_info mi ON t.id = mi.movie_id 
JOIN info_type i ON mi.info_type_id = i.id 
WHERE p.name LIKE '%Smith%' 
  AND t.production_year BETWEEN 2000 AND 2020 
  AND k.keyword IN ('Action', 'Drama') 
ORDER BY t.production_year DESC, p.name;
