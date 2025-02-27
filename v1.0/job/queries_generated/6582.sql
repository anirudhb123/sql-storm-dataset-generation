SELECT
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    c.role_id,
    cc.kind AS company_type,
    m.production_year,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    mt.linked_movie_id,
    it.info AS additional_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type cc ON mc.company_type_id = cc.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_link mt ON t.id = mt.movie_id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type it ON mi.info_type_id = it.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC,
    a.name ASC
LIMIT 100;
