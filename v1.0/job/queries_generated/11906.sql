SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    c.name AS company_name,
    mt.kind AS company_type,
    k.keyword AS movie_keyword,
    p.info AS person_info,
    r.role AS role_name,
    m.production_year
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    company_type mt ON mc.company_type_id = mt.id
JOIN
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    role_type r ON ci.role_id = r.id
JOIN
    title m ON t.movie_id = m.id
ORDER BY
    m.production_year DESC, a.name;
