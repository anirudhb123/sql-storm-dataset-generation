SELECT 
    ak.name AS aka_name,
    ti.title AS movie_title,
    ti.production_year,
    c.id AS cast_info_id,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ct.kind AS company_type,
    r.role AS role_name
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title ti ON c.movie_id = ti.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    movie_keyword mk ON ti.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON ti.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    ti.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ti.production_year DESC, ak.name;
