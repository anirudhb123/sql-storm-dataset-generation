SELECT
    a.name AS actor_name,
    a.imdb_index AS actor_imdb_index,
    t.title AS movie_title,
    t.production_year AS movie_year,
    p.info AS actor_bio,
    c.kind AS cast_type
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    title t ON ci.movie_id = t.id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    company_name cn ON cc.subject_id = cn.imdb_id
JOIN
    movie_companies mc ON t.id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    person_info p ON a.person_id = p.person_id
JOIN
    role_type r ON ci.role_id = r.id
JOIN
    movie_keyword mk ON t.id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%action%'
ORDER BY
    movie_year DESC, actor_name ASC;
