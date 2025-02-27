SELECT 
    t.title, 
    a.name, 
    c.nr_order, 
    ct.kind 
FROM 
    title t 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
