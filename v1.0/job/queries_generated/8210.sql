SELECT
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS character_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    GROUP_CONCAT(DISTINCT ctype.kind) AS company_types
FROM
    aka_title t
JOIN
    cast_info ci ON t.id = ci.movie_id
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    complete_cast cc ON t.id = cc.movie_id
JOIN
    char_name c ON cc.subject_id = c.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_type ctype ON mc.company_type_id = ctype.id
WHERE
    t.production_year BETWEEN 2000 AND 2020
    AND a.name IS NOT NULL
GROUP BY
    t.id, a.id, c.id
ORDER BY
    t.production_year DESC, movie_title, actor_name;
