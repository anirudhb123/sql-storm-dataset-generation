SELECT a.name, t.title, c.note, m.info
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.movie_id
JOIN movie_info m ON t.movie_id = m.movie_id
WHERE t.production_year = 2020;
