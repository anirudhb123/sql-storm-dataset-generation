-- Performance Benchmarking Query for Join Order Benchmark Schema

SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name
FROM
    aka_name AS a
JOIN
    cast_info AS c ON a.person_id = c.person_id
JOIN
    aka_title AS t ON c.movie_id = t.movie_id
JOIN
    movie_info AS m ON t.id = m.movie_id
JOIN
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN
    keyword AS k ON mk.keyword_id = k.id
JOIN
    movie_companies AS mc ON t.id = mc.movie_id
JOIN
    company_name AS cn ON mc.company_id = cn.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, actor_name;
