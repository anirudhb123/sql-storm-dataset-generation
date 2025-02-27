SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    pt.role AS role,
    c.name AS company_name,
    k.keyword AS keyword,
    pii.info AS info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    person_info pii ON a.person_id = pii.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
