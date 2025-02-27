SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.kind AS cast_type,
    p.info AS person_info,
    m.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
