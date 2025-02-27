SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    c.nr_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    ct.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    title ti ON t.movie_id = ti.id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, t.title;
