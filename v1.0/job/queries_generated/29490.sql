SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    ci.nr_order AS cast_order,
    rt.role AS role,
    COUNT(DISTINCT mc.company_id) AS production_companies_count,
    COUNT(DISTINCT mi.info_id) AS movie_info_count
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN
    movie_info mi ON t.movie_id = mi.movie_id
LEFT JOIN
    role_type rt ON ci.role_id = rt.id
WHERE
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY
    a.name, t.title, t.production_year, ci.nr_order, rt.role
ORDER BY
    t.production_year DESC, a.name;
