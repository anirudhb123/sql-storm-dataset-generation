SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    rd.role AS role_name,
    c.name AS company_name,
    m.info AS movie_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    role_type rd ON rd.id = ci.role_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON c.id = mc.company_id
JOIN 
    movie_info m ON m.movie_id = t.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year ASC, ak.name ASC;
