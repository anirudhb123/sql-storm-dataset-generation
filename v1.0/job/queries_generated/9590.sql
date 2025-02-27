SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    co.name AS company_name,
    COUNT(DISTINCT m.id) AS total_movies,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name co ON mc.company_id = co.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
JOIN
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE
    a.name IS NOT NULL
    AND t.production_year > 2000
GROUP BY
    a.id, t.id, c.kind, co.id
ORDER BY
    total_movies DESC, actor_name ASC;
