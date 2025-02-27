SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    ti.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    movie_info ti ON t.id = ti.movie_id
WHERE
    ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY
    t.production_year DESC;
