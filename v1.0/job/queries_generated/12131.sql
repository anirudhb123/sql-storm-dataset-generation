SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    ti.production_year
FROM
    title AS t
JOIN
    aka_title AS at ON t.id = at.movie_id
JOIN
    cast_info AS ci ON at.id = ci.movie_id
JOIN
    aka_name AS a ON ci.person_id = a.person_id
JOIN
    role_type AS c ON ci.role_id = c.id
JOIN
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN
    keyword AS k ON mk.keyword_id = k.id
ORDER BY
    ti.production_year DESC;
