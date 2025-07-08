SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    c.nr_order AS Actor_Order,
    ti.info AS Movie_Info,
    k.keyword AS Movie_Keyword,
    cn.name AS Company_Name,
    ct.kind AS Company_Type
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.subject_id = c.id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    t.production_year > 2000
AND 
    k.keyword LIKE '%Action%'
ORDER BY 
    t.title ASC, c.nr_order DESC;
