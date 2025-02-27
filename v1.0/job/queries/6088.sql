SELECT t.title, a.name AS actor_name, c.kind AS company_type, mi.info AS movie_info
FROM title t
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN company_type c ON mc.company_type_id = c.id
JOIN complete_cast cc ON t.id = cc.movie_id
JOIN aka_name a ON cc.subject_id = a.person_id
JOIN movie_info mi ON t.id = mi.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020
  AND c.kind ILIKE '%Production%'
  AND a.name IS NOT NULL
ORDER BY t.production_year DESC, t.title ASC
LIMIT 100;
