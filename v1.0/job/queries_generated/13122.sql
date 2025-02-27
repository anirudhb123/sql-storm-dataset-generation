SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.nr_order AS cast_order,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    mi.info AS movie_info
FROM
    title t
JOIN
    cast_info c ON t.id = c.movie_id
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type ci ON mc.company_type_id = ci.id
JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    t.production_year >= 2000
ORDER BY
    t.title, c.nr_order;
