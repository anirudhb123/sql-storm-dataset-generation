SELECT
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_name,
    cc.kind AS casting_kind,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name) AS production_companies,
    ti.info AS movie_info
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.movie_id
JOIN
    char_name c ON ci.person_role_id = c.id
JOIN
    comp_cast_type cc ON ci.role_id = cc.id
LEFT JOIN
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name cn ON mc.company_id = cn.id
LEFT JOIN
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN
    info_type ti ON mi.info_type_id = ti.id
WHERE
    t.production_year >= 2000 AND 
    cc.kind = 'actor'
GROUP BY
    a.name, t.title, c.note, cc.kind, ti.info
ORDER BY
    t.production_year DESC, a.name;
