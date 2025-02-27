SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.nr_order AS role_order, 
    ci.kind AS company_type, 
    mi.info AS movie_info
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
WHERE 
    a.name ILIKE '%Smith%'
    AND t.production_year BETWEEN 2000 AND 2023
    AND ci.kind_id IN (SELECT id FROM comp_cast_type WHERE kind LIKE 'Full Cast')
ORDER BY 
    t.production_year DESC, 
    role_order ASC;
