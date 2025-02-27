SELECT
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.person_role_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    ca.kind AS cast_type,
    m_info.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name comp ON mc.company_id = comp.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    comp_cast_type ca ON c.person_role_id = ca.id
JOIN
    movie_info m_info ON t.id = m_info.movie_id
WHERE
    t.production_year > 2000
ORDER BY
    t.production_year DESC, a.name;
