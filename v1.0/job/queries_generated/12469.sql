SELECT 
    a.name AS aka_name, 
    t.title AS movie_title, 
    ci.nr_order AS cast_order, 
    p.gender AS person_gender, 
    ct.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    info_type it ON t.id = it.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
ORDER BY 
    t.production_year DESC, ci.nr_order;
