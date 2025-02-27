SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS character_type, 
    cc.info AS company_info, 
    mk.keyword AS movie_keyword 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    role_type c ON ci.role_id = c.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
WHERE 
    t.production_year > 2000 
    AND c.kind LIKE '%actor%' 
    AND mk.keyword IS NOT NULL 
ORDER BY 
    t.production_year DESC, a.name;
