SELECT a.name AS aka_name,
       t.title AS movie_title,
       c.note AS cast_note,
       p.info AS person_info,
       m.info AS movie_info,
       k.keyword AS movie_keyword
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.movie_id
JOIN person_info p ON c.person_id = p.person_id
JOIN movie_info m ON c.movie_id = m.movie_id
JOIN movie_keyword k ON c.movie_id = k.movie_id
WHERE t.production_year = 2020
  AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
ORDER BY a.name, t.title;
