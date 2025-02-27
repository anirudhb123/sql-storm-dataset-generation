SELECT
    t.title AS movie_title,
    ak.name AS actor_name,
    p.info AS person_info,
    mt.kind AS movie_type,
    c.name AS company_name,
    k.keyword AS movie_keyword
FROM
    title t
JOIN
    aka_title ak_t ON t.id = ak_t.movie_id
JOIN
    cast_info c_info ON ak_t.id = c_info.person_id
JOIN
    aka_name ak ON c_info.person_id = ak.person_id
JOIN
    company_name c ON c.id = (SELECT company_id FROM movie_companies mc WHERE mc.movie_id = t.id LIMIT 1)
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    person_info p ON ak.person_id = p.person_id
JOIN
    kind_type mt ON t.kind_id = mt.id
ORDER BY
    t.production_year DESC, ak.name;
