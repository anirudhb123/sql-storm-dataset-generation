SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    r.role AS role_type,
    c.note AS cast_note,
    co.name AS company_name,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    ti.info AS title_info
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON a.person_id = c.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info_idx ti ON t.id = ti.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
