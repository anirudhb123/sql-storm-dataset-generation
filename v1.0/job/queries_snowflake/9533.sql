SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS additional_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.movie_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%Action%'
ORDER BY
    t.production_year DESC,
    a.name,
    c.nr_order;
