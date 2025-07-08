SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    k.keyword AS movie_keyword, 
    c.kind AS company_type, 
    p.info AS director_info 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    title t ON ci.movie_id = t.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    person_info p ON cc.subject_id = p.person_id 
WHERE 
    c.kind LIKE 'Distributor%' 
AND 
    t.production_year >= 2000 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
