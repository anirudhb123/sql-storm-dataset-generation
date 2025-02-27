SELECT 
    t.title, 
    a.name, 
    c.note 
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    cast_info c ON cc.movie_id = c.movie_id AND cc.subject_id = c.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC;
