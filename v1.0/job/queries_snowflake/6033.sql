SELECT ak.name AS aka_name,
       t.title AS movie_title,
       c.nr_order AS cast_order,
       p.name AS actor_name,
       comp.name AS company_name,
       ct.kind AS company_type,
       mi.info AS movie_info
FROM aka_name ak
JOIN cast_info c ON ak.person_id = c.person_id
JOIN title t ON c.movie_id = t.id
JOIN name p ON c.person_id = p.imdb_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name comp ON mc.company_id = comp.id
JOIN company_type ct ON mc.company_type_id = ct.id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE t.production_year >= 2000
  AND ct.kind = 'Distributor'
  AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY t.production_year DESC, ak.name, t.title;
