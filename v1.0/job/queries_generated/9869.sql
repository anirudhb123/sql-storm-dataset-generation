SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    co.name AS company_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    mi.info AS movie_info
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    role_type c ON ci.role_id = c.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
WHERE
    t.production_year >= 2000
    AND co.country_code = 'USA'
GROUP BY
    a.name, t.title, c.kind, co.name, mi.info
ORDER BY
    t.production_year DESC, a.name;
