SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    c.kind AS company_type
FROM 
    aka_name a 
JOIN 
    cast_info ci ON a.person_id = ci.person_id 
JOIN 
    aka_title t ON ci.movie_id = t.movie_id 
JOIN 
    movie_info m ON t.id = m.movie_id 
JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
JOIN 
    keyword k ON mk.keyword_id = k.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_type c ON mc.company_type_id = c.id 
WHERE 
    a.name LIKE 'J%' 
    AND t.production_year > 2000 
    AND c.kind IN ('Distributor', 'Producer')
ORDER BY 
    t.production_year DESC, a.name;
