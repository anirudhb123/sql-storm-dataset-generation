SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.person_id,
    cn.name AS company_name,
    rt.role AS role
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    role_type rt ON c.role_id = rt.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, ak.name;
