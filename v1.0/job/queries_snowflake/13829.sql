SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ct.kind AS company_type,
    m.name AS company_name
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    t.production_year DESC, 
    n.name;
