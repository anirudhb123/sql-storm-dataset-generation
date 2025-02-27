SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    c.name AS company_name,
    ct.kind AS company_type,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    title t ON at.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
