SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    cc.kind AS comp_cast_type,
    cn.name AS company_name,
    kt.keyword AS movie_keyword
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    comp_cast_type cc ON ci.person_role_id = cc.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword kt ON mk.keyword_id = kt.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name;
