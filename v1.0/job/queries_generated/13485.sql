SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS cast_note,
    co.name AS company_name,
    ki.keyword AS movie_keyword,
    rt.role AS role_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
