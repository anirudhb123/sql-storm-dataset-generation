SELECT 
    ak.name AS aka_name,
    ti.title AS title,
    pi.info AS person_info,
    ct.kind AS cast_type,
    cn.name AS company_name
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    title ti ON ci.movie_id = ti.id
JOIN
    person_info pi ON ak.person_id = pi.person_id
JOIN
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN
    movie_companies mc ON ti.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
WHERE
    ti.production_year >= 2000
ORDER BY
    ti.production_year DESC;
