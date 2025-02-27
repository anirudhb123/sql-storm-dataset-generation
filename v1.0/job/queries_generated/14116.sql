SELECT
    t.title,
    a.name AS actor_name,
    c.kind AS company_type,
    m.info AS movie_info
FROM
    title t
JOIN
    movie_info m ON t.id = m.movie_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name a ON ci.person_id = a.person_id
WHERE
    t.production_year BETWEEN 2000 AND 2023
ORDER BY
    t.production_year DESC, a.name ASC;
