SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.person_role_id, 
    p.info AS person_info,
    k.keyword AS movie_keyword,
    ct.kind AS company_type
FROM 
    title t
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
    person_info p ON ci.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    t.production_year DESC, 
    t.title, 
    ak.name;
