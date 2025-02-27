SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info,
    m.production_year,
    count(DISTINCT m.id) AS total_movies
FROM
    title AS t
JOIN
    cast_info AS ci ON t.id = ci.movie_id
JOIN
    aka_name AS a ON ci.person_id = a.person_id
JOIN
    movie_companies AS mc ON t.id = mc.movie_id
JOIN
    company_type AS c ON mc.company_type_id = c.id
JOIN
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN
    person_info AS pi ON a.person_id = pi.person_id
WHERE
    m.production_year >= 2000
    AND c.kind LIKE '%Production%'
GROUP BY
    t.title, a.name, c.kind, k.keyword, pi.info, m.production_year
ORDER BY
    total_movies DESC;
