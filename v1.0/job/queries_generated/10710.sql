SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS company_type,
    ti.info AS info_type
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    person_info pi ON a.person_id = pi.person_id
JOIN 
    info_type ti ON pi.info_type_id = ti.id
WHERE 
    t.production_year > 2000
ORDER BY 
    a.name, t.title;
