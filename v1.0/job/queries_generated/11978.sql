SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS role_order,
    ct.kind AS character_type,
    c.name AS company_name,
    wi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type ct ON ci.person_role_id = ct.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info wi ON t.id = wi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.title, a.name, ci.nr_order;
