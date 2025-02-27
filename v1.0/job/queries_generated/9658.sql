SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    r.role AS role_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM
    cast_info c
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    role_type r ON c.role_id = r.id
LEFT JOIN
    movie_info m ON t.id = m.movie_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY
    t.production_year DESC,
    a.name,
    c.nr_order;
