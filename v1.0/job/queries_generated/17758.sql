SELECT t.title, a.name, c.note 
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name c ON mc.company_id = c.id
JOIN aka_name a ON mc.movie_id = a.person_id
WHERE t.production_year = 2021
ORDER BY t.title;
