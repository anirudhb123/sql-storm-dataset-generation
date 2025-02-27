SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    p.name AS person_name, 
    r.role AS person_role, 
    c.note AS cast_note, 
    y.production_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_name co ON cc.subject_id = co.id
JOIN 
    company_type ct ON co.id = ct.id
WHERE 
    y.production_year >= 2000
ORDER BY 
    a.name, y.production_year DESC;
