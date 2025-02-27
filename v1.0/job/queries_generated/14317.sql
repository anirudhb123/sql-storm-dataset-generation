SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.note AS character_note,
    c.kind AS comp_cast_type,
    ci.nr_order AS role_order,
    t.production_year
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
