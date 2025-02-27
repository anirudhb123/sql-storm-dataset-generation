SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_kind,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info
FROM
    title t
JOIN
    aka_title at ON t.id = at.movie_id
JOIN
    cast_info ci ON at.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN
    keyword ki ON mk.keyword_id = ki.id
JOIN
    movie_info mi ON ci.movie_id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name;
