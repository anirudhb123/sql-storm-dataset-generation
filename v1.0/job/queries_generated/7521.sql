SELECT 
    a.name AS person_name,
    t.title AS movie_title,
    c.note AS role_note,
    co.name AS company_name,
    ct.kind AS company_type,
    ti.kind AS movie_kind,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    kind_type ti ON t.kind_id = ti.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
    AND co.country_code = 'USA'
    AND a.surname_pcode IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
