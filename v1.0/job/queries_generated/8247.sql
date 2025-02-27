SELECT
    ak.name AS actor_name,
    ti.title AS movie_title,
    ti.production_year AS production_year,
    ct.kind AS company_type,
    c.name AS company_name,
    mw.keyword AS movie_keyword,
    pi.info AS actor_info
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    title ti ON ci.movie_id = ti.id
JOIN
    movie_companies mc ON ti.id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_keyword mw ON ti.id = mw.movie_id
JOIN
    keyword k ON mw.keyword_id = k.id
JOIN
    person_info pi ON ak.person_id = pi.person_id
WHERE
    ti.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Producer'
    AND pi.info_type_id IN (1, 2, 3)
ORDER BY
    ti.production_year DESC,
    ak.name ASC;
