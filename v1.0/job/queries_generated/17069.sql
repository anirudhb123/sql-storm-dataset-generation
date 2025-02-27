SELECT t.title, a.name, c.note
FROM title t
JOIN aka_title at ON t.id = at.movie_id
JOIN cast_info c ON at.id = c.movie_id
JOIN aka_name a ON c.person_id = a.person_id
WHERE t.production_year = 2022;
