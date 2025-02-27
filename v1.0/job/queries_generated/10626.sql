SELECT
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
    company.name AS company_name,
    mi.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.movie_id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name company ON mc.company_id = company.id
JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    a.name IS NOT NULL
    AND t.title IS NOT NULL
    AND c.note IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY
    a.name, t.title;
