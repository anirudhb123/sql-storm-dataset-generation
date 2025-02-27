SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cm.name AS company_name,
    c_type.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mw ON t.id = mw.movie_id
JOIN 
    keyword k ON mw.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    company_type c_type ON mc.company_type_id = c_type.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
