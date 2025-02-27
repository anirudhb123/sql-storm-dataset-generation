SELECT
    a.id AS aka_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS title_name,
    t.production_year,
    c.id AS cast_id,
    p.id AS person_id,
    p.name AS person_name,
    k.keyword AS movie_keyword,
    ct.kind AS company_type,
    ci.note AS cast_note
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    name p ON a.person_id = p.imdb_id
WHERE
    t.production_year >= 2000
    AND k.keyword IS NOT NULL
ORDER BY
    t.production_year DESC,
    a.name ASC,
    k.keyword ASC
LIMIT 100;
