SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    c.note AS role_note,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    i.info AS movie_info
FROM aka_name a
JOIN cast_info c ON a.person_id = c.person_id
JOIN aka_title t ON c.movie_id = t.movie_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name m ON mc.company_id = m.id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN person_info p ON a.person_id = p.person_id
JOIN movie_info i ON t.id = i.movie_id
WHERE t.production_year BETWEEN 2000 AND 2020 
AND c.nr_order < 5
AND i.note LIKE '%award%'
ORDER BY t.production_year DESC, a.name ASC;
