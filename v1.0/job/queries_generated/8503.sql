SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    ci.country_code AS company_country,
    ci.name AS company_name,
    ti.info AS movie_info
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
    role_type rt ON ci.role_id = rt.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type it ON mi.info_type_id = it.id
JOIN
    kind_type kt ON t.kind_id = kt.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND it.info = 'Box Office'
    AND cn.country_code = 'USA'
ORDER BY
    t.production_year DESC,
    a.name ASC;
