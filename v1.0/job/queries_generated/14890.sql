SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS cast_type,
    c.name AS company_name,
    k.keyword AS keyword,
    ti.info AS movie_info
FROM
    title t
JOIN
    cast_info ci ON t.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
JOIN
    role_type rt ON ci.role_id = rt.id
ORDER BY
    t.production_year DESC, 
    a.name;
