SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    y.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    t.production_year >= 2000
    AND c.kind != 'uncredited'
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
GROUP BY
    a.name, t.title, c.kind, y.production_year
ORDER BY
    keyword_count DESC, t.title ASC
LIMIT 100;
