SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.order AS cast_order,
    p.info AS actor_info,
    ct.kind AS company_type,
    co.name AS company_name,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Production'
    AND it.info = 'Biography'
ORDER BY 
    t.production_year DESC, ak.name;
