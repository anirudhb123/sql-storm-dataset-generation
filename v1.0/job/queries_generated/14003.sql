SELECT 
    ak.id AS aka_id,
    ak.name AS aka_name,
    t.id AS title_id,
    t.title AS movie_title,
    ci.person_id,
    ci.note AS cast_note,
    p.name AS person_name,
    p.gender AS person_gender,
    c.kind AS company_type,
    mt.note AS movie_note
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON ci.person_id = p.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_info_idx mt ON t.id = mt.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
