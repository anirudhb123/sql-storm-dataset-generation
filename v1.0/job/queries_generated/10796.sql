SELECT a.name AS aka_name,
       t.title AS movie_title,
       pt.role AS person_role,
       ci.note AS cast_info_note,
       m.info AS movie_info
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN movie_info m ON t.id = m.movie_id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC, a.name;
