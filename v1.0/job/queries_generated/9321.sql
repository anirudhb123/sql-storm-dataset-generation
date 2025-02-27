SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    rt.role AS role_type, 
    co.name AS company_name, 
    k.keyword AS movie_keyword, 
    ta.production_year AS release_year
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title ta ON t.id = ta.movie_id
WHERE 
    ta.production_year > 2000
ORDER BY 
    ta.production_year DESC, 
    actor_name, 
    movie_title;
