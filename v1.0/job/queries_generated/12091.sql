SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.nr_order,
    ci.kind AS company_type
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type cct ON mc.company_type_id = cct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, ak.name;
