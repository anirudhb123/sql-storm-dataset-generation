SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    mk.keyword AS movie_keyword,
    cn.name AS company_name,
    ti.info AS movie_info
FROM
    title t
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    company_name cn ON t.id = cn.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND mk.keyword IN ('Action', 'Drama', 'Comedy')
    AND a.name IS NOT NULL
ORDER BY
    t.production_year DESC, a.name, mk.keyword;
