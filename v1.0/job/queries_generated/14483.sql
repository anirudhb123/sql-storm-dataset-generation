SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_name,
    c.note AS cast_note,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    t.production_year >= 2000 
ORDER BY 
    t.title, a.name;
