SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    tc.kind AS company_type,
    p.info AS person_info,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    role_type c ON ci.role_id = c.id
GROUP BY
    a.name, t.title, c.kind, tc.kind, p.info
HAVING
    COUNT(DISTINCT k.keyword) > 5
ORDER BY
    actor_name ASC, movie_title ASC;
