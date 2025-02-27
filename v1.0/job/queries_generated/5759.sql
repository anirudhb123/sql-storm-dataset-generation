SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    COUNT(DISTINCT c.id) AS total_companies
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
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
WHERE
    t.production_year BETWEEN 2000 AND 2023
GROUP BY
    a.id, t.id
ORDER BY
    total_companies DESC,
    actor_name ASC;
