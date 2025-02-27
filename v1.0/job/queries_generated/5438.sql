SELECT
    t.title,
    a.name AS actor_name,
    cct.kind AS cast_type,
    mn.name AS company_name,
    mi.info AS movie_info,
    kw.keyword AS movie_keyword
FROM
    title t
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name mn ON mc.company_id = mn.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    role_type rt ON ci.role_id = rt.id
JOIN
    comp_cast_type cct ON ci.person_role_id = cct.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    t.production_year >= 2000
    AND mn.country_code = 'USA'
ORDER BY
    t.production_year DESC, a.name;
