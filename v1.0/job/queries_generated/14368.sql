SELECT
    ak.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    m.production_year,
    k.keyword AS movie_keyword
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type c ON mc.company_type_id = c.id
JOIN
    person_info pi ON ak.person_id = pi.person_id
JOIN
    keyword k ON t.id = k.movie_id
JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    ak.name IS NOT NULL
    AND t.production_year > 2000
ORDER BY
    t.production_year DESC;
