SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS actor_order,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS additional_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name m ON mc.company_id = m.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    info_type i ON mi.info_type_id = i.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
ORDER BY
    t.production_year DESC,
    a.name ASC,
    c.nr_order;
