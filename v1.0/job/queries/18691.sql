SELECT 
    t.title, 
    p.name AS person_name, 
    c.note AS cast_note 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name p ON c.person_id = p.person_id 
WHERE 
    t.production_year = 2020;
