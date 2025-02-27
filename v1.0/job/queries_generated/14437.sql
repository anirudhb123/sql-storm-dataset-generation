-- Performance Benchmarking Query
SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role_type,
    m.production_year,
    k.keyword AS movie_keyword,
    p.info AS actor_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
