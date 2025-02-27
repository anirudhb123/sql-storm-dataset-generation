
SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year AS year,
    STRING_AGG(DISTINCT k.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies,
    p.info AS person_info
FROM
    aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN aka_title t ON ci.movie_id = t.movie_id
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
JOIN movie_companies mc ON t.id = mc.movie_id
JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE
    t.production_year >= 2000
    AND k.keyword LIKE '%Action%'
GROUP BY
    a.name, t.title, t.production_year, p.info
ORDER BY
    t.production_year DESC, a.name ASC;
