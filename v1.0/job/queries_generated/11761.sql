SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS cast_role,
    ct.kind AS company_type,
    ti.info AS additional_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    a.name IS NOT NULL
ORDER BY
    t.production_year DESC;
