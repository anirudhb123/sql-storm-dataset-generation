SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    tp.kind AS company_type,
    mcn.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
JOIN 
    company_type tp ON mc.company_type_id = tp.id
JOIN 
    company_name mcn ON mc.company_id = mcn.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, a.name;
