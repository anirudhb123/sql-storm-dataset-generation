SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    pt.role AS person_role,
    ci.kind AS cast_type,
    co.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type pt ON c.role_id = pt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND ak.name IS NOT NULL
    AND mi.info_type_id IN (
        SELECT id 
        FROM info_type 
        WHERE info LIKE '%Award%'
    )
ORDER BY 
    t.production_year DESC, 
    ak.name;
