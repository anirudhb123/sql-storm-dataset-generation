SELECT 
    t.title, 
    a.name AS actor_name, 
    p.info AS person_info, 
    c.kind AS company_kind, 
    k.keyword AS movie_keyword 
FROM 
    aka_title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
JOIN 
    aka_name a ON a.person_id = ci.person_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON k.id = mk.keyword_id
JOIN 
    person_info p ON p.person_id = a.person_id
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.title, a.name;
