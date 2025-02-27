SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS actor_order,
    ci.kind AS company_type,
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
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
    AND ct.kind LIKE '%Film%'
ORDER BY 
    a.name ASC, 
    t.production_year DESC, 
    c.nr_order ASC;
