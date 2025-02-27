SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.role_id, 
    ci.note AS cast_note 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name ak ON c.person_id = ak.person_id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
WHERE 
    t.production_year > 2000 
ORDER BY 
    t.title;
