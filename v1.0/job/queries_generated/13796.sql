SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    ct.kind AS role_type, 
    ci.note AS company_note, 
    m.production_year 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    company_type ct ON mc.company_type_id = ct.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    title m ON t.id = m.id 
WHERE 
    m.production_year >= 2000 
ORDER BY 
    m.production_year DESC, 
    a.name;
