SELECT
    t.title,
    c.name AS cast_name,
    ct.kind AS role_type,
    ak.name AS aka_name,
    m.company_id,
    mc.name AS company_name,
    mi.info AS movie_info,
    k.keyword
FROM
    title t
JOIN
    cast_info c ON t.id = c.movie_id
JOIN
    role_type ct ON c.role_id = ct.id
JOIN
    aka_name ak ON c.person_id = ak.person_id
JOIN
    movie_companies m ON t.id = m.movie_id
JOIN
    company_name mc ON m.company_id = mc.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year > 2000
ORDER BY
    t.title, cast_name;
