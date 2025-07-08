SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    c.nr_order AS cast_order,
    p.name AS person_name,
    comp.name AS company_name,
    k.keyword AS movie_keyword,
    m.info AS movie_info
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    name p ON ak.person_id = p.imdb_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
WHERE 
    t.production_year >= 2000 
    AND c.role_id IN (SELECT id FROM role_type WHERE role LIKE 'actor%')
ORDER BY 
    t.production_year DESC, 
    ak.name, 
    movie_title;
