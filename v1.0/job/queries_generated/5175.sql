SELECT 
    t.title AS Movie_Title,
    ak.name AS Actor_Name,
    c.kind AS Cast_Type,
    cn.name AS Company_Name,
    mi.info AS Movie_Info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND ak.name LIKE '%Smith%' 
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC, 
    ak.name ASC;
