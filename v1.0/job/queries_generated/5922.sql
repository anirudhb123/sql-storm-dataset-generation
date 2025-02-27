SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS cast_order, 
    p.info AS actor_info, 
    k.keyword AS keyword, 
    co.name AS company_name, 
    ct.kind AS company_type, 
    ti.info AS additional_info 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
LEFT JOIN 
    company_name co ON mc.company_id = co.id 
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id 
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id 
LEFT JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND k.keyword IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
