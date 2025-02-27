SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    c.id AS cast_id, 
    p.info AS person_info, 
    k.keyword AS movie_keyword, 
    cn.name AS company_name, 
    ct.kind AS company_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000 
    AND ct.kind IS NOT NULL 
ORDER BY 
    t.production_year DESC, a.name;
