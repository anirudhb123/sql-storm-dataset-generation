SELECT 
    a.name AS aka_name,
    m.title AS movie_title,
    c.note AS cast_note,
    ci.kind AS company_type,
    k.keyword AS movie_keyword,
    i.info AS movie_info,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type ci ON mc.company_type_id = ci.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    info_type i ON mi.info_type_id = i.id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.production_year DESC;
