SELECT a.name AS actor_name,
       t.title AS movie_title,
       c.kind AS cast_type,
       comp.name AS company_name,
       k.keyword AS associated_keyword,
       mi.info AS movie_info
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN movie_companies mc ON cc.movie_id = mc.movie_id
JOIN company_name comp ON mc.company_id = comp.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE a.name LIKE 'A%'
  AND t.production_year > 2000
  AND comp.country_code = 'USA'
  AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY t.production_year DESC, a.name;
