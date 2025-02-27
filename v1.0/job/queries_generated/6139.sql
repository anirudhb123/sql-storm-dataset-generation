SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS role_type,
    c.name AS company_name,
    minfo.info AS movie_info,
    mk.keyword AS movie_keyword
FROM
    title t
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    role_type rt ON ci.role_id = rt.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    movie_info minfo ON t.id = minfo.movie_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
WHERE
    t.production_year >= 2000 
    AND a.name IS NOT NULL
    AND minfo.note IS NOT NULL
ORDER BY
    t.production_year DESC, a.name ASC
LIMIT 100;
