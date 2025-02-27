SELECT 
    t.title, 
    p.name AS person_name, 
    k.keyword, 
    c.kind AS company_type, 
    ti.info AS movie_info
FROM 
    title t 
JOIN 
    cast_info ci ON t.id = ci.movie_id 
JOIN 
    aka_name p ON ci.person_id = p.person_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
JOIN 
    movie_info ti ON t.id = ti.movie_id 
WHERE 
    t.production_year > 2000 
    AND c.kind = 'Distributor' 
    AND ti.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, 
    p.name ASC;
