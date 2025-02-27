SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role,
    c.note AS cast_note,
    m.production_year
FROM
    title AS t
JOIN
    aka_title AS at ON t.id = at.movie_id
JOIN
    cast_info AS c ON at.movie_id = c.movie_id
JOIN
    aka_name AS a ON c.person_id = a.person_id
JOIN
    role_type AS r ON c.role_id = r.id
JOIN
    movie_info AS mi ON t.id = mi.movie_id
JOIN
    info_type AS it ON mi.info_type_id = it.id
WHERE
    it.info = 'Director'
    AND m.production_year >= 2000
ORDER BY
    m.production_year DESC;
