SELECT 
    n.name AS person_name,
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    c.kind AS company_type,
    ct.kind AS role_type,
    m.production_year
FROM 
    name n
JOIN 
    aka_name a ON n.id = a.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON n.id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type ct ON ci.role_id = ct.id
ORDER BY 
    m.production_year DESC, n.name;
