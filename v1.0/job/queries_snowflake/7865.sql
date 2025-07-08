SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    ci.note AS cast_note, 
    ci.nr_order, 
    c2.name AS company_name, 
    k.keyword AS movie_keyword 
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id 
JOIN 
    movie_companies mc ON mc.movie_id = t.id 
JOIN 
    company_name c2 ON mc.company_id = c2.id 
JOIN 
    movie_keyword mk ON mk.movie_id = t.id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year > 2000 
    AND c.kind != 'uncredited' 
ORDER BY 
    t.production_year DESC, 
    a.name ASC 
LIMIT 100;
