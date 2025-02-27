SELECT 
    p.id AS person_id,
    p.name AS person_name,
    t.title AS movie_title,
    c.note AS role_note,
    comp.name AS company_name,
    m.production_year,
    k.keyword AS movie_keyword
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    comp.country_code = 'USA' 
    AND m.production_year >= 2000
ORDER BY 
    m.production_year DESC, 
    p.name ASC;
