SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.personal_role_id,
    c.nr_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    comp.name AS company_name,
    mt.kind AS company_type,
    vi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info vi ON t.movie_id = vi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
