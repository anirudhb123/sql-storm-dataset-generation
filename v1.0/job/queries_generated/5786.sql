SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    COALESCE(t.production_year, 'Unknown') AS production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names
FROM
    cast_info ci
JOIN
    aka_name a ON ci.person_id = a.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
WHERE
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL
GROUP BY
    a.name, t.title, c.kind, t.production_year
ORDER BY
    production_year DESC, actor_name ASC;
