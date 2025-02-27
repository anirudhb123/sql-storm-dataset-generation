SELECT 
    t.title, 
    c.name AS company_name, 
    k.keyword, 
    p.info, 
    a.name AS actor_name 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.id = ci.movie_id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year >= 2000 
AND 
    k.keyword ILIKE '%action%' 
AND 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography') 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;