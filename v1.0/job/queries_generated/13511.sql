SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_type,
    c.note AS cast_note
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    role_type r ON c.role_id = r.id
JOIN
    person_info pi ON a.person_id = pi.person_id
WHERE
    t.production_year BETWEEN 2000 AND 2020
ORDER BY
    t.production_year DESC, a.name;
