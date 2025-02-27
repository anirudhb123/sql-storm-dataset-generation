SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    k.keyword AS movie_keyword
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    n.name;
