SELECT 
    t.title, 
    p.name AS person_name, 
    c.kind AS cast_kind
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year = 2021
ORDER BY 
    t.title;
