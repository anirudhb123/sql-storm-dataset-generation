SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    ct.kind AS company_type,
    mc.note AS company_note,
    mi.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Distributor'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY
    t.production_year DESC,
    a.name;
