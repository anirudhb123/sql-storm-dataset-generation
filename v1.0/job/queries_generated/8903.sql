SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_biography,
    c.kind AS role_type,
    GROUP_CONCAT(k.keyword) AS keywords
FROM
    title t
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    cast_info ci ON ci.movie_id = cc.movie_id AND ci.person_id = cc.subject_id
JOIN
    aka_name a ON a.person_id = ci.person_id
JOIN
    role_type c ON c.id = ci.role_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN
    keyword k ON k.id = mk.keyword_id
LEFT JOIN
    person_info p ON p.person_id = a.person_id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind IN (SELECT kind FROM comp_cast_type WHERE kind LIKE '%actor%')
GROUP BY
    t.id, a.name, p.info, c.kind
ORDER BY
    t.production_year DESC, a.name ASC;
