SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_kind,
    k.keyword AS movie_keyword,
    m.info AS movie_info,
    pi.info AS person_info
FROM
    title t
JOIN
    aka_title at ON t.id = at.movie_id
JOIN
    cast_info ci ON at.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type c ON mc.company_type_id = c.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    info_type it ON mi.info_type_id = it.id
LEFT JOIN
    person_info pi ON a.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate' LIMIT 1)
WHERE
    c.kind LIKE '%Production%'
    AND t.production_year BETWEEN 2000 AND 2023
ORDER BY
    t.title, a.name;
