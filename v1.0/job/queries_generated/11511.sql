SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    c.nr_order AS cast_order,
    mt.kind AS company_type,
    ki.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name n ON c.person_id = n.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    n.name;
