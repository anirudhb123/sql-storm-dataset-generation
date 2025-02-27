-- Performance Benchmarking Query for Join Order Benchmark Schema

SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ch.name AS character_name,
    co.name AS company_name,
    mt.kind AS company_type,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.movie_id
JOIN
    char_name ch ON c.person_role_id = ch.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
JOIN
    company_type mt ON mc.company_type_id = mt.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    t.production_year >= 2000
ORDER BY
    a.name, t.production_year DESC;
