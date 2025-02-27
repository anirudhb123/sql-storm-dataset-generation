SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
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
    title mt ON t.id = mt.id
WHERE 
    a.name IS NOT NULL
    AND k.keyword IS NOT NULL
ORDER BY 
    m.production_year DESC, t.title;
