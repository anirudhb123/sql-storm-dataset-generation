SELECT
    t.title AS movie_title,
    ak.name AS actor_name,
    p.info AS actor_info,
    m.name AS company_name,
    k.keyword AS movie_keyword
FROM
    title t
JOIN
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN
    cast_info c ON ak_t.id = c.movie_id
JOIN
    aka_name ak ON c.person_id = ak.person_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name m ON mc.company_id = m.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    person_info p ON ak.person_id = p.person_id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC, t.title ASC;
