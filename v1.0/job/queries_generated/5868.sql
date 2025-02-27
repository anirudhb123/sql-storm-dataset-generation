SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    p.info AS person_info,
    r.role AS role_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type,
    m.production_year,
    mi.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year > 2000
    AND k.keyword LIKE '%drama%'
ORDER BY 
    t.production_year DESC, 
    a.name;
