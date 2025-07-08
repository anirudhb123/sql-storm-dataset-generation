SELECT 
    t.title, 
    ak.name AS aka_name, 
    c.note AS cast_note 
FROM 
    title t 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    cast_info c ON t.id = c.movie_id 
JOIN 
    aka_name ak ON c.person_id = ak.person_id 
WHERE 
    k.keyword = 'Action'
ORDER BY 
    t.production_year DESC;
