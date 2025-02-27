SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    c.role_id AS role_id,
    a.name AS aka_name,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM
    title t
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name comp ON mc.company_id = comp.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    aka_name a ON cc.subject_id = a.person_id
JOIN
    cast_info ci ON cc.movie_id = ci.movie_id
JOIN
    name p ON ci.person_id = p.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type i ON mi.info_type_id = i.id
WHERE
    t.production_year >= 2000
ORDER BY 
    t.title, p.name;
