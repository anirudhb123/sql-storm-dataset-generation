SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.type AS role_type,
    m.production_year,
    k.keyword,
    com.name AS company_name
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC, 
    t.title ASC;
