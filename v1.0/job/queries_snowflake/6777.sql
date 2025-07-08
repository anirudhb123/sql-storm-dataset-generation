SELECT t.title, a.name, c.nr_order, ct.kind, cn.name AS company_name, mi.info
FROM title t
JOIN cast_info c ON t.id = c.movie_id
JOIN aka_name a ON c.person_id = a.person_id 
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN comp_cast_type ct ON c.person_role_id = ct.id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020
AND a.name ILIKE '%Smith%'
AND ct.kind = 'actor'
ORDER BY t.production_year DESC, c.nr_order;
