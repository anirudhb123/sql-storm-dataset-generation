SELECT
    t.title AS movie_title,
    ak.name AS actor_name,
    ct.kind AS role_name,
    company.name AS company_name,
    movie_info.info AS additional_info,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM
    title t
JOIN
    cast_info ci ON t.id = ci.movie_id
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    role_type ct ON ci.role_id = ct.id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_name company ON mc.company_id = company.id
LEFT JOIN
    movie_info ON t.id = movie_info.movie_id 
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year >= 2000
    AND ak.name IS NOT NULL
    AND COALESCE(movie_info.info, '') <> ''
GROUP BY
    t.title,
    ak.name,
    ct.kind,
    company.name,
    movie_info.info
ORDER BY
    keyword_count DESC,
    ak.name ASC,
    t.title ASC;
