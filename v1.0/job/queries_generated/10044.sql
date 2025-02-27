-- Performance Benchmarking Query
SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role_name,
    c.kind AS comp_cast_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM
    aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN role_type r ON ci.role_id = r.id
JOIN complete_cast cc ON ci.movie_id = cc.movie_id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_type ct ON mc.company_type_id = ct.id
JOIN company_name cn ON mc.company_id = cn.id
JOIN movie_info m ON t.id = m.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN person_info pi ON a.person_id = pi.person_id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, a.name;
