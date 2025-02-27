SELECT 
    p.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    r.role AS role_name, 
    co.name AS company_name, 
    k.keyword AS movie_keyword 
FROM 
    cast_info c 
JOIN 
    aka_name p ON c.person_id = p.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    role_type r ON c.role_id = r.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    role_order ASC;
