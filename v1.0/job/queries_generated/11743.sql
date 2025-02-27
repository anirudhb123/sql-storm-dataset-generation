SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    mi.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Overview')
ORDER BY
    a.name, t.production_year;
