SELECT 
    t.title AS movie_title,
    p.name AS person_name,
    r.role AS role,
    c.note AS cast_note,
    m.company_id,
    m.note AS movie_company_note
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies m ON t.id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, p.name;
