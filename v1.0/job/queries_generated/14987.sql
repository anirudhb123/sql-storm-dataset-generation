SELECT
    ak.name AS aka_name,
    t.title AS title,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name
FROM
    aka_name ak
JOIN
    cast_info c ON ak.person_id = c.person_id
JOIN
    title t ON c.movie_id = t.id
JOIN
    person_info p ON ak.person_id = p.person_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
ORDER BY
    ak.name, t.title;
