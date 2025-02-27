SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    m.name AS company_name,
    ct.kind AS company_type,
    ti.info AS additional_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
LEFT JOIN
    movie_info m_info ON t.id = m_info.movie_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name m ON mc.company_id = m.id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN
    person_info p ON a.person_id = p.person_id
LEFT JOIN
    info_type ti ON p.info_type_id = ti.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name, c.nr_order;
