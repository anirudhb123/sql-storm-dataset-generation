SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ct.kind AS company_type,
    ki.keyword AS movie_keyword,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON ci.movie_id = t.id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type ct ON ct.id = mc.company_type_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword ki ON ki.id = mk.keyword_id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type ti ON ti.id = mi.info_type_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    t.title, 
    a.name;
