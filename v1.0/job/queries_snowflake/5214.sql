
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    ct.kind AS company_type,
    pi.info AS person_info
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name cn ON mc.company_id = cn.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    person_info pi ON a.person_id = pi.person_id
WHERE
    t.production_year >= 2000 AND
    ct.kind = 'Distributor'
GROUP BY
    a.name, t.title, t.production_year, ct.kind, pi.info
ORDER BY
    t.production_year DESC, a.name;
