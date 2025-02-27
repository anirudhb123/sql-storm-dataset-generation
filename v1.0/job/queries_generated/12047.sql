SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS role_type,
    m.production_year,
    k.keyword AS movie_keyword,
    c2.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c2 ON mc.company_id = c2.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    a.name;
