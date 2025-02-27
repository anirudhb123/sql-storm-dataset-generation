SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS cast_type,
    m.name AS company_name,
    k.keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC;
