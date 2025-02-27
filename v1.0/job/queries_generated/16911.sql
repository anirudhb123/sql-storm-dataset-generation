SELECT t.title, n.name, c.note
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
JOIN cast_info c ON t.id = c.movie_id
JOIN aka_name n ON c.person_id = n.person_id
WHERE t.production_year >= 2000
ORDER BY t.title, n.name;
