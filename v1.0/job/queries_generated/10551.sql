SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    p.name AS person_name,
    c.kind AS cast_type,
    ci.info AS company_info,
    k.keyword AS movie_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    name p ON ci.person_id = p.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    comp_cast_type cc ON ci.role_id = cc.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    a.name;
