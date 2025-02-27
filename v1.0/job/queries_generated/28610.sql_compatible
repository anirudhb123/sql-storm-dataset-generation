
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ' ORDER BY k.keyword) AS keywords,
    ci.note AS role_note,
    p.info AS person_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE
    t.production_year > 2000
    AND a.name LIKE '%Smith%'
GROUP BY
    a.name, t.title, t.production_year, ci.note, p.info
HAVING
    COUNT(DISTINCT k.id) >= 3
ORDER BY
    t.production_year DESC, a.name;
