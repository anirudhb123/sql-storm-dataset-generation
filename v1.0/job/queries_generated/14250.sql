-- Performance benchmarking query for Join Order Benchmark schema
SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    p.info,
    k.keyword,
    n.name AS character_name,
    co.name AS company_name,
    ci.kind AS company_type,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    char_name n ON c.role_id = n.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    role_type r ON c.person_role_id = r.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
