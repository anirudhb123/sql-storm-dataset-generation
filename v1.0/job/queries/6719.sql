SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.name AS company_name, 
    k.keyword AS movie_keyword, 
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON mi.movie_id = t.id
JOIN 
    info_type i ON mi.info_type_id = i.id
WHERE 
    a.name LIKE 'A%' AND 
    t.production_year > 2000 AND 
    c.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name;
