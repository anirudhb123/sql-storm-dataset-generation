SELECT 
    t.title AS movie_title, 
    a.name AS actor_name, 
    r.role AS role_name, 
    c.name AS company_name, 
    k.keyword AS movie_keyword 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    role_type r ON ci.role_id = r.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023 
    AND a.name IS NOT NULL 
    AND c.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
