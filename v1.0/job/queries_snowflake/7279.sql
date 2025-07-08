SELECT 
    p.name AS actor_name, 
    t.title AS movie_title, 
    c.note AS cast_note, 
    k.keyword AS movie_keyword, 
    cn.name AS company_name, 
    ct.kind AS company_type, 
    mi.info AS movie_info
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
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
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000 
    AND ct.kind = 'Production' 
    AND k.keyword LIKE '%Action%'
ORDER BY 
    t.production_year DESC, 
    p.name;
