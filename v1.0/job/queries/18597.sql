SELECT
    t.title,
    a.name AS actor_name,
    p.info AS actor_info
FROM
    title AS t
JOIN
    movie_companies AS mc ON t.id = mc.movie_id
JOIN
    company_name AS cn ON mc.company_id = cn.id
JOIN
    cast_info AS ci ON t.id = ci.movie_id
JOIN
    aka_name AS a ON ci.person_id = a.person_id
JOIN
    person_info AS p ON a.person_id = p.person_id
WHERE
    t.production_year >= 2000
    AND cn.country_code = 'USA'
ORDER BY
    t.title;
