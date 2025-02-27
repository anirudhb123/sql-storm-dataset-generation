SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS character_role,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    mi.info AS movie_info,
    ti.info AS title_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
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
AND 
    a.name IS NOT NULL 
AND 
    co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name ASC
LIMIT 100;
