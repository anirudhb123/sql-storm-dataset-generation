SELECT
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.person_role_id,
    r.role,
    comp.name AS company_name,
    m.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    role_type r ON c.role_id = r.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name comp ON mc.company_id = comp.id
LEFT JOIN
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND comp.country_code = 'USA'
    AND r.role LIKE '%Actor%'
ORDER BY
    t.production_year DESC, aka_name ASC
LIMIT 100;
