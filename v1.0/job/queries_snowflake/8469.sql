
SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    COUNT(m.keyword_id) AS keyword_count,
    i.info AS movie_info
FROM
    title t
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON cc.subject_id = ci.id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    movie_keyword m ON t.id = m.movie_id
JOIN
    keyword k ON m.keyword_id = k.id
JOIN
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    info_type i ON mi.info_type_id = i.id
WHERE
    t.production_year >= 2000
GROUP BY
    t.title, a.name, c.kind, i.info
HAVING
    COUNT(m.keyword_id) > 1
ORDER BY
    t.title, a.name;
