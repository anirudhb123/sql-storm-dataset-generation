SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
