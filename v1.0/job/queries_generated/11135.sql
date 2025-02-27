SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS role_type,
    m.name AS company_name,
    k.keyword AS movie_keyword
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type c ON ci.role_id = c.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name;
