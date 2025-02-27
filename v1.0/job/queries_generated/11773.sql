SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS person_role,
    c.note AS cast_note,
    ci.kind AS comp_cast_type,
    ci.company_id,
    mk.keyword AS movie_keyword,
    m.info AS movie_info
FROM
    aka_name AS a
JOIN
    cast_info AS c ON a.person_id = c.person_id
JOIN
    title AS t ON c.movie_id = t.id
JOIN
    role_type AS r ON c.role_id = r.id
JOIN
    movie_companies AS mc ON t.id = mc.movie_id
JOIN
    company_name AS cn ON mc.company_id = cn.id
JOIN
    comp_cast_type AS ci ON mc.company_type_id = ci.id
JOIN
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN
    movie_info AS m ON t.id = m.movie_id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name;
