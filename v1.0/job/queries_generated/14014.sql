SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    k.keyword AS keyword,
    co.name AS company_name,
    m.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, t.title;
