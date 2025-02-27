SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order,
    ct.kind AS company_type,
    cmp.name AS company_name
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cmp ON mc.company_id = cmp.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
