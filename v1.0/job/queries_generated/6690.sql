SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    k.keyword AS movie_keyword, 
    c.kind AS company_type, 
    p.info AS person_info
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
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    person_info p ON cc.subject_id = p.person_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
    AND ct.kind = 'Distributor'
ORDER BY 
    a.name, t.production_year DESC
LIMIT 50;
