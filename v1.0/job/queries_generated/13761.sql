SELECT
    t.title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS role_type,
    m.production_year,
    k.keyword
FROM
    title t
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.person_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year BETWEEN 1990 AND 2020
ORDER BY
    t.production_year DESC, a.name;
