SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    p.info AS actor_info,
    k.keyword AS movie_keyword,
    i.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info i ON t.id = i.movie_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    AND c.kind LIKE 'Production%'
ORDER BY 
    t.production_year DESC, a.name;
