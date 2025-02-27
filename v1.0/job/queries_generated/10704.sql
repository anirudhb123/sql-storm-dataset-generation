SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    m.info AS movie_info,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    person_info p ON a.person_id = p.person_id
WHERE 
    t.production_year >= 2000
AND 
    cn.country_code = 'USA'
ORDER BY 
    t.production_year DESC;
