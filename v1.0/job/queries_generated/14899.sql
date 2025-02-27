SELECT
    t.title,
    a.name AS actor_name,
    c.kind AS character_name,
    comp.name AS company_name,
    k.keyword AS movie_keyword
FROM
    title t
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name comp ON mc.company_id = comp.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    char_name ch ON ci.role_id = ch.id
JOIN
    role_type r ON ci.role_id = r.id
WHERE
    t.production_year >= 2000
ORDER BY
    t.title, a.name;
