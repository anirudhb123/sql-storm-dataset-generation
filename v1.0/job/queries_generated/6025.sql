SELECT 
    p.name AS person_name,
    t.title AS movie_title,
    c.role_id AS role_id,
    co.name AS company_name,
    k.keyword AS movie_keyword,
    ci.kind AS company_type,
    ti.info AS movie_info
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    p.name ILIKE '%Smith%'
AND 
    t.production_year >= 2000
AND 
    ct.kind = 'Distributor'
ORDER BY 
    t.production_year DESC, p.name;
