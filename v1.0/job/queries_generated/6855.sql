SELECT 
    a.name AS Actor_Name, 
    t.title AS Movie_Title, 
    c.kind AS Cast_Type, 
    ti.info AS Movie_Info, 
    k.keyword AS Movie_Keyword, 
    p.info AS Person_Info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type rt ON ci.role_id = rt.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    company_type c ON cc.subject_id = c.id
WHERE 
    t.production_year >= 2000 
    AND (it.info LIKE '%award%' OR it.info LIKE '%nominated%')
ORDER BY 
    t.production_year DESC, a.name;
