-- Performance Benchmarking SQL Query

SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.info AS person_info,
    ct.kind AS comp_cast_type,
    ci.note AS cast_info_note
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
