SELECT
    akn.name AS actor_name,
    ttl.title AS movie_title,
    cnt.name AS company_name,
    ct.kind AS company_type,
    ti.info AS movie_info,
    kw.keyword AS movie_keyword
FROM
    aka_name akn
JOIN
    cast_info ci ON akn.person_id = ci.person_id
JOIN
    title ttl ON ci.movie_id = ttl.id
JOIN
    movie_companies mc ON ttl.id = mc.movie_id
JOIN
    company_name cnt ON mc.company_id = cnt.id
JOIN
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN
    movie_info mi ON ttl.id = mi.movie_id
LEFT JOIN
    info_type it ON mi.info_type_id = it.id
LEFT JOIN
    movie_keyword mk ON ttl.id = mk.movie_id
LEFT JOIN
    keyword kw ON mk.keyword_id = kw.id
WHERE
    ttl.production_year > 2000
    AND akn.name IS NOT NULL
ORDER BY
    ttl.production_year DESC, akn.name;
