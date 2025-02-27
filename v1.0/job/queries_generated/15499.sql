SELECT t.title, a.name, c.note
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name c ON mc.company_id = c.id
JOIN cast_info ca ON t.id = ca.movie_id
JOIN aka_name a ON ca.person_id = a.person_id
WHERE t.production_year = 2020;
