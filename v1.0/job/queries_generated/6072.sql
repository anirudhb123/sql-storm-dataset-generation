SELECT 
    t.title AS Movie_Title, 
    a.name AS Actor_Name, 
    p.info AS Actor_Info, 
    c.kind AS Company_Kind, 
    k.keyword AS Movie_Keyword, 
    ti.info AS Movie_Info
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    person_info p ON a.person_id = p.person_id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name c ON mc.company_id = c.id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_info mi ON t.id = mi.movie_id 
JOIN 
    info_type ti ON mi.info_type_id = ti.id 
WHERE 
    t.production_year > 2000 
    AND c.country_code = 'USA' 
    AND p.info_type_id IN (1, 2) 
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
