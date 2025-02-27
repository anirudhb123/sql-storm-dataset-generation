SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    rt.role AS role_name,
    ci.kind AS comp_cast_type,
    co.name AS company_name,
    mi.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    aka_name an
JOIN 
    cast_info c ON an.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type rt ON c.role_id = rt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type ci ON c.person_role_id = ci.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND co.country_code = 'USA'
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
