SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year, 
    c.kind AS comp_cast_type, 
    g.kind AS company_type, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type g ON mc.company_type_id = g.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND c.kind LIKE '%Lead%' 
    AND g.kind = 'Production'
ORDER BY 
    t.production_year DESC, 
    a.name;
