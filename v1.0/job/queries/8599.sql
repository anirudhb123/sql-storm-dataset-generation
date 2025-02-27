SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    mf.info AS movie_info,
    rt.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mf ON t.id = mf.movie_id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id = 1  
ORDER BY 
    t.production_year DESC, c.nr_order;