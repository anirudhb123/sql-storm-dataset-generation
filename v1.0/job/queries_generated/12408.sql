SELECT
    a.id AS aka_name_id,
    a.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    c.person_id AS cast_person_id,
    c.movie_id AS cast_movie_id,
    r.role AS person_role,
    m.name AS company_name,
    k.keyword AS movie_keyword
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    role_type r ON c.role_id = r.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name m ON mc.company_id = m.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    a.name IS NOT NULL
ORDER BY
    a.name, t.production_year;
