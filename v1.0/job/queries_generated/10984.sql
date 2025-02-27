SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role_type,
    p.info AS person_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    person_info p ON a.person_id = p.person_id
WHERE
    t.production_year BETWEEN 2000 AND 2020
ORDER BY
    t.production_year, a.name;
