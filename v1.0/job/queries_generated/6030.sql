SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    cc.kind AS company_kind,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    p.info AS person_info
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
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_info m ON t.id = m.movie_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    person_info p ON a.person_id = p.person_id
WHERE
    t.production_year >= 2000
    AND ct.kind = 'Production'
    AND k.keyword LIKE '%action%'
ORDER BY
    t.production_year DESC,
    a.name;
