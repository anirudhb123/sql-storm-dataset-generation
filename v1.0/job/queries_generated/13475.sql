SELECT
    t.title,
    a.name AS actor_name,
    c.nr_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM
    title t
JOIN
    cast_info c ON t.id = c.movie_id
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name;
