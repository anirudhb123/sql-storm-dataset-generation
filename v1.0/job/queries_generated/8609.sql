SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.note AS role_note, 
    cy.name AS company_name, 
    k.keyword AS movie_keyword, 
    ti.info AS movie_info 
FROM 
    cast_info c 
JOIN 
    aka_name a ON c.person_id = a.person_id 
JOIN 
    aka_title t ON c.movie_id = t.movie_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cy ON mc.company_id = cy.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
WHERE 
    t.production_year >= 2000 
    AND c.nr_order = 1 
    AND ti.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis') 
ORDER BY 
    t.production_year DESC, 
    a.name;
