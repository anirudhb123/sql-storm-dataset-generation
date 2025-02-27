SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    rt.role AS actor_role,
    c.note AS cast_note,
    pc.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    role_type rt ON rt.id = c.role_id
JOIN 
    person_info pi ON pi.person_id = a.person_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON co.id = mc.company_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year, a.name;
