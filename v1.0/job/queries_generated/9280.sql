SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    ct.kind AS cast_type,
    co.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    keyword k ON t.id = k.movie_id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
WHERE 
    t.production_year > 2000
    AND a.name ILIKE '%Smith%'
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
