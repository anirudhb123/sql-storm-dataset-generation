SELECT
    a.name AS actor_name,
    m.title AS movie_title,
    c.note AS character_name,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title m ON c.movie_id = m.movie_id
JOIN
    movie_companies mc ON m.id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_keyword mk ON m.id = mk.movie_id
JOIN
    keyword ki ON mk.keyword_id = ki.id
JOIN
    movie_info mi ON m.id = mi.movie_id
JOIN
    info_type ti ON mi.info_type_id = ti.id
ORDER BY
    m.production_year DESC, a.name ASC;
