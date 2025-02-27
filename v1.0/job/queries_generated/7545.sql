SELECT
    t.title AS movie_title,
    c.name AS actor_name,
    p.info AS actor_info,
    ct.kind AS role_type,
    mc.note AS company_note,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM
    title t
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name an ON ci.person_id = an.person_id
JOIN
    name n ON an.person_id = n.imdb_id
JOIN
    person_info p ON n.imdb_id = p.person_id
JOIN
    role_type rt ON ci.role_id = rt.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_info mi ON t.id = mi.movie_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year > 2000
AND
    ct.kind = 'Distributor'
ORDER BY
    t.production_year DESC,
    actor_name;
