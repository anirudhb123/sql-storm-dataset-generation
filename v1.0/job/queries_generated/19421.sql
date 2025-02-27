SELECT 
    t.title, 
    p.name AS person_name, 
    ct.kind AS company_type, 
    k.keyword 
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
WHERE 
    t.production_year >= 2020
ORDER BY 
    t.production_year DESC;
