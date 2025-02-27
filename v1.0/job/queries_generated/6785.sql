SELECT
    p.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    mc.company_name AS production_company,
    ti.info AS movie_info,
    k.keyword AS movie_keyword
FROM
    cast_info ci
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND ti.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    AND c.kind IN ('Actor', 'Actress')
ORDER BY 
    t.production_year DESC, p.name ASC;
