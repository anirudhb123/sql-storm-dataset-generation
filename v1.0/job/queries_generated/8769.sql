SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    pc.info AS person_info,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_info_idx ti ON t.id = ti.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind = 'Lead'
    AND m.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name;
