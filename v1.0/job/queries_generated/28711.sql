SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mk.keyword) AS num_keywords,
    LENGTH(t.title) AS title_length,
    COALESCE(MAX(m.info), 'No additional info') AS additional_info
FROM
    title t
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    cast_info ci ON t.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    movie_info m ON t.id = m.movie_id
WHERE
    cn.country_code = 'USA'
    AND t.production_year BETWEEN 2000 AND 2023
    AND LENGTH(a.name) > 5
GROUP BY
    t.title, a.name, ct.kind
ORDER BY
    num_keywords DESC, title_length DESC;

