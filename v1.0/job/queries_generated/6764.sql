SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    r.role AS role_type,
    co.name AS company_name,
    mt.kind AS company_type,
    ti.info AS movie_info,
    li.link AS movie_link
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN title t ON c.movie_id = t.id
JOIN person_info p ON a.person_id = p.person_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN role_type r ON c.role_id = r.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name co ON mc.company_id = co.id
JOIN company_type mt ON mc.company_type_id = mt.id
JOIN movie_info mi ON t.id = mi.movie_id
JOIN info_type ti ON mi.info_type_id = ti.id
JOIN movie_link ml ON t.id = ml.movie_id
JOIN link_type li ON ml.link_type_id = li.id
WHERE t.production_year >= 2000
AND k.keyword ILIKE '%action%'
ORDER BY t.production_year DESC, a.name;
