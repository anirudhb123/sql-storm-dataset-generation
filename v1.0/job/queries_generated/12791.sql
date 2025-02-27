SELECT a.name AS aka_name, 
       t.title AS movie_title, 
       c.nr_order AS cast_order, 
       n.name AS person_name, 
       co.name AS company_name, 
       kt.keyword AS movie_keyword 
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN title t ON c.movie_id = t.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword kt ON mk.keyword_id = kt.id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_name co ON mc.company_id = co.id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, c.nr_order;
