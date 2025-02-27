SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role,
    y.production_year,
    m.name AS company_name,
    k.keyword AS movie_keyword
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name m ON mc.company_id = m.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    role_type r ON ci.role_id = r.id
JOIN
    aka_title y ON t.id = y.movie_id
ORDER BY
    y.production_year DESC, t.title;
