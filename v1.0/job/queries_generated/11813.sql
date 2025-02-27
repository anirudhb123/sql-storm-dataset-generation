SELECT 
    ak.name AS aka_name, 
    t.title, 
    c.role_id,
    pm.name AS person_name, 
    ci.note AS cast_note,
    cc.kind AS comp_cast_type, 
    mc.note AS movie_company_note,
    mi.info AS movie_info_text,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    company_name cn ON cn.id IN (SELECT company_id FROM movie_companies WHERE movie_id = t.id)
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    company_type ct ON ct.id = (SELECT company_type_id FROM movie_companies WHERE movie_id = t.id LIMIT 1)
JOIN 
    role_type rt ON rt.id = c.role_id
ORDER BY 
    t.production_year DESC, 
    ak.name;
