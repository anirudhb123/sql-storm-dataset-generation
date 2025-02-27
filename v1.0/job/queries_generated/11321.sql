SELECT 
    t.title AS Movie_Title,
    p.name AS Person_Name,
    c.nr_order AS Cast_Order,
    a.name AS Alias_Name,
    k.keyword AS Movie_Keyword,
    cct.kind AS Cast_Type
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    person_info pi ON c.person_id = pi.person_id
JOIN 
    keyword k ON t.id = k.id
JOIN 
    comp_cast_type cct ON c.person_role_id = cct.id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, 
    c.nr_order;
