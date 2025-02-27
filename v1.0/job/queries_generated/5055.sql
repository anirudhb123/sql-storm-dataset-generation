SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS actor_role,
    mw.keyword AS movie_keyword,
    c.name AS company_name,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword mw ON mk.keyword_id = mw.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
AND 
    r.role LIKE 'actor%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
