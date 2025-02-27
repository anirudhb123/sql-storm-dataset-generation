SELECT a.name AS actor_name,
       t.title AS movie_title,
       c.kind AS category,
       ci.note AS role_note,
       m.info AS movie_info,
       k.keyword AS associated_keyword
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN movie_info m ON t.movie_id = m.movie_id
JOIN movie_keyword mk ON t.movie_id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN comp_cast_type c ON ci.person_role_id = c.id
WHERE t.production_year >= 2000
  AND a.name IS NOT NULL
  AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY t.production_year DESC, a.name;
