SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    m.year AS production_year,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    title m ON t.movie_id = m.id
JOIN
    movie_companies mc ON m.id = mc.movie_id
JOIN
    company_name c ON mc.company_id = c.id
JOIN
    movie_keyword mk ON m.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    m.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
GROUP BY
    a.name, t.title, m.production_year, c.kind
ORDER BY
    m.production_year DESC, a.name ASC;
