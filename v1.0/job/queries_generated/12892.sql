-- Performance Benchmarking Query using Join Order Benchmark schema

SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    c.nr_order AS order_in_cast,
    ct.kind AS company_type,
    k.keyword AS movie_keyword,
    mi.info AS movie_information,
    p.info AS person_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.movie_id
JOIN
    company_name cn ON cn.id = (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = t.movie_id LIMIT 1)
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    person_info p ON a.person_id = p.person_id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name, t.title;
