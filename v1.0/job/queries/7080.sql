SELECT 
    p.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type, 
    k.keyword AS movie_keyword, 
    mi.info AS movie_info
FROM 
    cast_info ci 
JOIN 
    aka_name p ON ci.person_id = p.person_id 
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
JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    t.production_year >= 2000 
    AND c.kind LIKE 'Production%' 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
ORDER BY 
    t.production_year DESC, 
    actor_name ASC;
