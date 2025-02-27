SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_name,
    m.company_name AS production_company,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    m.country_code = 'USA' 
    AND t.production_year BETWEEN 2000 AND 2023
    AND k.keyword LIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
