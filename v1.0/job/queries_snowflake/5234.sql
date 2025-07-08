SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    pi.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    t.production_year > 2000
AND 
    c.kind LIKE 'Distribution%'
ORDER BY 
    t.production_year DESC, a.name;
