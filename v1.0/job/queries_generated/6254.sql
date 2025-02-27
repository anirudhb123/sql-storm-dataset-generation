SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    p.info AS person_bio,
    COUNT(k.keyword) AS keyword_count
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    person_info p ON a.person_id = p.person_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year >= 2000
    AND a.name IS NOT NULL
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY
    a.name, t.title, c.kind, p.info
HAVING
    COUNT(k.keyword) > 0
ORDER BY
    keyword_count DESC, t.title ASC
LIMIT 100;
