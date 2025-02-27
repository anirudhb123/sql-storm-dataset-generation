SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    ct.kind AS company_type,
    m.pass AS movie_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.movie_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_info m ON t.id = m.movie_id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Distributor'
    AND a.name LIKE '%Smith%'
ORDER BY
    t.production_year DESC, 
    c.nr_order;
