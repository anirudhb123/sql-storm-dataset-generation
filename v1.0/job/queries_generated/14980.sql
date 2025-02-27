SELECT t.title, p.name, c.note, comp.name AS company_name, ki.info 
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name comp ON mc.company_id = comp.id
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN aka_name p ON cc.subject_id = p.person_id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN info_type ki ON mi.info_type_id = ki.id
WHERE t.production_year > 2000
ORDER BY t.title, p.name;
