SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    c.kind AS cast_type, 
    k.keyword AS movie_keyword, 
    co.name AS company_name, 
    mi.info AS additional_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    comp_cast_type c ON c.id = ci.person_role_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name co ON co.id = mc.company_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND c.kind IN ('actor', 'actress')
ORDER BY 
    t.title, a.name;
