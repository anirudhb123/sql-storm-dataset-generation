SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    ct.kind AS comp_cast_type,
    cn.name AS company_name
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type ct ON c.role_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
