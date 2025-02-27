SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_name,
    rt.role AS role_name,
    COUNT(DISTINCT m.id) AS movie_count
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title t ON ci.movie_id = t.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    role_type rt ON ci.role_id = rt.id
GROUP BY
    a.name, t.title, t.production_year, c.kind, rt.role
ORDER BY
    movie_count DESC;
