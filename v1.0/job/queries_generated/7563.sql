SELECT 
    p.name AS person_name,
    m.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS cast_type,
    co.name AS company_name,
    mt.info AS movie_info
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    complete_cast cc ON m.id = cc.movie_id
JOIN 
    movie_info_idx mt ON m.id = mt.movie_id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    AND mt.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    m.production_year DESC, 
    c.nr_order;
