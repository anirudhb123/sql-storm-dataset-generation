SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.nr_order,
    r.role AS character_name,
    co.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, a.name;
