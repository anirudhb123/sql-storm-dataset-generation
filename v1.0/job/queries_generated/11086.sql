SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    ci.note AS cast_note,
    pn.info AS person_info,
    ct.kind AS cast_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    person_info pn ON a.person_id = pn.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
