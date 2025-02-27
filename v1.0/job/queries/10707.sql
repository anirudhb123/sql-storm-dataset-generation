SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    rt.role AS actor_role,
    ct.kind AS company_type,
    cn.name AS company_name
FROM 
    title t
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
