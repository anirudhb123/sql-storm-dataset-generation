SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ci.kind AS company_type,
    m.production_year,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    title m ON t.movie_id = m.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, a.name;
