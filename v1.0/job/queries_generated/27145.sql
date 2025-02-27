SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.role_id,
    COALESCE(k.keyword, '') AS keyword,
    mc.company_name AS production_company,
    mi.info AS movie_info,
    COUNT(DISTINCT c.person_id) AS total_actors,
    COUNT(DISTINCT m.id) AS total_movies_linked
FROM
    aka_title t
JOIN
    cast_info c ON t.id = c.movie_id
JOIN
    aka_name a ON c.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    movie_link m ON m.movie_id = t.id
WHERE
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY
    t.title, a.name, c.role_id, k.keyword, mc.company_name, mi.info
ORDER BY
    total_actors DESC, movie_title ASC
LIMIT 50;
