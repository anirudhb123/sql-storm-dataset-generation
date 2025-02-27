-- Performance benchmarking SQL query for Join Order Benchmark schema

SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    m.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    company_name cn ON ci.movie_id = cn.id
JOIN
    movie_info m ON t.id = m.movie_id
JOIN
    comp_cast_type c ON ci.person_role_id = c.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
ORDER BY
    t.production_year, a.name;
