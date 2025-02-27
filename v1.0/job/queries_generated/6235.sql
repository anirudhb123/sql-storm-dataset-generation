SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    tc.kind AS company_type, 
    c.name AS company_name, 
    r.role AS cast_role, 
    ti.info AS movie_info 
FROM 
    aka_name a 
JOIN 
    cast_info ca ON a.person_id = ca.person_id 
JOIN 
    title t ON ca.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    role_type r ON ca.role_id = r.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
WHERE 
    a.name LIKE '%Smith%' 
    AND t.production_year BETWEEN 2000 AND 2020 
    AND ct.kind IN ('Distributor', 'Producer') 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
