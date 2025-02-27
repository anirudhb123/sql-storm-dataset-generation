SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.role AS cast_role,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    p.info AS person_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
WHERE 
    a.name ILIKE '%Smith%' 
    AND t.production_year >= 2000
    AND k.keyword ILIKE '%action%'
ORDER BY 
    t.production_year DESC, 
    a.name;
