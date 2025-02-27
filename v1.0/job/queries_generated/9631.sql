SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS character_note,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info,
    rt.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name LIKE 'A%'
ORDER BY 
    t.production_year DESC, a.name;
