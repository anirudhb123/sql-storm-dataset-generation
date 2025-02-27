
SELECT a.name AS actor_name, 
       t.title AS movie_title, 
       c.nr_order AS role_order, 
       ct.kind AS cast_type, 
       mc.note AS company_note, 
       mi.info AS movie_info, 
       STRING_AGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.movie_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type ct ON mc.company_type_id = ct.id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
WHERE a.name LIKE 'A%' AND t.production_year > 2000
GROUP BY a.name, t.title, c.nr_order, ct.kind, mc.note, mi.info
ORDER BY a.name, t.title;
