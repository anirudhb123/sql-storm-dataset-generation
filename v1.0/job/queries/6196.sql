SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    kc.keyword AS movie_keyword,
    c.name AS company_name,
    ct.kind AS company_type,
    r.role AS role_type,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND kc.keyword LIKE '%action%'
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.title, a.name;
