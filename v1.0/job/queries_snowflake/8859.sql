SELECT a.name AS actor_name, t.title AS movie_title, p.info AS actor_info, c.kind AS cast_type, k.keyword AS movie_keyword
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN comp_cast_type c ON ci.person_role_id = c.id
JOIN person_info p ON a.id = p.person_id
WHERE t.production_year > 2000
  AND k.keyword LIKE '%action%'
  AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio')
ORDER BY t.production_year DESC, a.name ASC;
