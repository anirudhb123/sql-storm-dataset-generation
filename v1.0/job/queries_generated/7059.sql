SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    p.info AS actor_info,
    c.kind AS company_type,
    m.info AS movie_detail,
    k.keyword AS movie_keyword,
    r.role AS actor_role
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword k ON mi.id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IN ('Production', 'Distribution')
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name, t.title;
