SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_role,
    k.keyword AS movie_keyword,
    cti.info AS movie_info,
    cn.name AS company_name
FROM
    title t
JOIN
    cast_info ci ON t.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type cti ON mi.info_type_id = cti.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
ORDER BY
    t.production_year DESC, a.name, t.title;
