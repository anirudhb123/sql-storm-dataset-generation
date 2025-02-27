SELECT 
    a.name AS aka_name,
    at.title AS movie_title,
    c.note AS cast_note,
    cn.name AS company_name,
    mt.kind AS company_type,
    k.keyword AS movie_keyword,
    t.title AS orig_title,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title t ON at.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
ORDER BY 
    at.production_year DESC, a.name;
