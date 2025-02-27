
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    ct.kind AS company_type,
    COUNT(DISTINCT m.company_id) AS company_count,
    AVG(CAST(mi.info AS INTEGER)) AS avg_movie_rating
FROM
    aka_name a
JOIN
    cast_info c ON a.person_id = c.person_id
JOIN
    aka_title t ON c.movie_id = t.id
LEFT JOIN
    movie_companies m ON t.id = m.movie_id
LEFT JOIN
    company_type ct ON m.company_type_id = ct.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
WHERE
    t.production_year BETWEEN 1990 AND 2020
GROUP BY
    a.name, t.title, c.role_id, ct.kind
HAVING
    COUNT(DISTINCT m.company_id) > 1
ORDER BY
    avg_movie_rating DESC, actor_name ASC;
